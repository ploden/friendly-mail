//
//  MailProvider.swift
//  friendly-mail
//
//  Created by Philip Loden on 12/8/21.
//

import Foundation
import MailCore
import CocoaLumberjackSwift

struct MailProvider {
    let settings: Settings
    private(set) var messages: MessageStore
    private let imapSession: MCOIMAPSession
    
    func new(withSettings: Settings) -> MailProvider {
        let newWith = MailProvider(settings: settings, messages: self.messages)
        return newWith
    }
    
    func new(mergingMessages messages: [MessageID : BaseMessage]) -> MailProvider {
        var newWith = self
        let newMessages = self.messages.merging(messages: messages)
        newWith.messages = newMessages
        return newWith
    }
    
    func new(mergingMessageStores messageStore: MessageStore) -> MailProvider {
        var newWith = self
        let newMessages = self.messages.merging(messageStore: messageStore)
        newWith.messages = newMessages
        return newWith
    }
    
    init(settings: Settings, messages: MessageStore) {
        self.settings = settings
        self.messages = messages
        let session = MCOIMAPSession()
        session.hostname = "imap.gmail.com"
        session.port = 993
        //session.oAuth2Token = settings.authState?.lastTokenResponse?.accessToken
        session.authType = MCOAuthType.xoAuth2
        session.username = settings.user.address
        //session.password = settings.password
        session.connectionType = .TLS
        self.imapSession = session
    }
    
}

extension MailProvider: MessageSender {
    
    func sendMessage(to: [Address], subject: String?, htmlBody: String?, plainTextBody: String, friendlyMailHeaders: [HeaderKeyValue]?, completion: @escaping (Error?, MessageID?) -> ()) {
        guard settings.isValid else {
            completion(NSError(domain: "fm", code: 1, userInfo: [:]), nil)
            return
        }
        
        settings.authState?.performAction(freshTokens: { accessToken, idToken, freshTokensError in
            guard let accessToken = accessToken else {
                completion(freshTokensError, nil)
                return
            }
            
            let session = MCOSMTPSession()
            session.port = 465
            session.username = settings.user.address
            //session.password = settings.password
            session.authType = MCOAuthType.xoAuth2
            session.oAuth2Token = accessToken
            session.connectionType = .TLS
            
            session.hostname = "smtp.gmail.com"
            //session.connectionType = MCOConnectionType.TLS
            
            let builder = MCOMessageBuilder()
            builder.header.to = to.compactMap { MCOAddress(displayName: $0.name, mailbox: $0.address) }
            builder.header.from = MCOAddress(displayName: settings.user.address, mailbox: settings.user.address)
            builder.header.subject = subject
            
            if let friendlyMailHeaders = friendlyMailHeaders {
                let pairs = friendlyMailHeaders.compactMap { "\($0.key)=\($0.value)" }
                let joined = pairs.joined(separator: "; ")
                builder.header.setExtraHeaderValue(joined, forName: HeaderName.friendlymail.rawValue)
            }
            
            builder.htmlBody = htmlBody
            builder.textBody = plainTextBody
            
            let rfc822Data = builder.data()
            
            let sendOperation = session.sendOperation(with: rfc822Data)
            
            sendOperation?.start { (error) -> Void in
                if let error = error {
                    DDLogDebug("MailController: sendMessage: send failed with error: \(error)")
                } else {
                    DDLogDebug("MailController: sendMessage: send succeeded")
                }
                completion(error, error == nil ? builder.header.messageID : nil)
            }
        })
    }
    
    func moveMessageToInbox(message: BaseMessage, completion: @escaping (Error?) -> ()) {
        let requestKind: MCOIMAPStoreFlagsRequestKind = .add
        let labels = ["\\Inbox", MailboxName.friendlyMail]
        
        let operation = imapSession.storeLabelsOperation(withFolder: message.uidWithMailbox.mailbox.name, uids: MCOIndexSet(index: message.uidWithMailbox.UID), kind: requestKind, labels: labels)
        operation?.start({ error in
                completion(error)
        })
    }
    
}

extension MailProvider: MessageReceiver {

    func getMail(withMailbox mailbox: Mailbox, completion: @escaping (Error?, MessageStore?) -> ()) {
        guard settings.isValid else {
            completion(NSError(domain: "fm", code: 1, userInfo: [:]), nil)
            return
        }
        
        let requestKind: MCOIMAPMessagesRequestKind = .fullHeaders
        
        settings.authState?.performAction(freshTokens: { accessToken, idToken, freshTokensError in
            guard let accessToken = accessToken else {
                completion(freshTokensError, nil)
                return
            }
            
            imapSession.oAuth2Token = accessToken
            
            let folderOperation = imapSession.folderInfoOperation(mailbox.name)
            
            DispatchQueue.global(qos: .default).async {
                var outerError: Error? = nil
                var outerMessageStore: MessageStore? = nil
                
                folderOperation?.start { folderOperationError, folderInfo in
                    if let folderInfo = folderInfo {
                        let maxNum = 50
                        
                        let messageCount = Int(folderInfo.messageCount)
                        let location = max(1, messageCount - maxNum)
                        let length = min(maxNum, messageCount)
                        let numbers = MCOIndexSet(range: MCORange(location: UInt64(location), length: UInt64(length)))
                        
                        let fetchOperation: MCOIMAPFetchMessagesOperation = imapSession.fetchMessagesByNumberOperation(withFolder: mailbox.name, requestKind: requestKind, numbers: numbers)
                        
                        let downloadGroup = DispatchGroup()
                        
                        downloadGroup.enter()
                        fetchOperation.start { fetchMessagesError, fetchedMessages, vanishedMessages in
                            if let fetchMessagesError = fetchMessagesError {
                                DDLogDebug("MailController: getMail: error: \(String(describing: fetchMessagesError))")
                                outerError = fetchMessagesError
                            } else {
                                let messages: [BaseMessage]? = fetchedMessages?.compactMap {
                                    if let header = MessageHeader(header: $0.header, mailbox: mailbox) {
                                        let messageID = UIDWithMailbox(UID: UInt64($0.uid), mailbox: mailbox)
                                        return MessageFactory.createMessage(settings: self.settings, uidWithMailbox: messageID, header: header, htmlBody: nil, plainTextBody: nil)
                                    }
                                    return nil
                                }
                                outerMessageStore = {
                                    if let messages = messages {
                                        let messagesDict = Dictionary(uniqueKeysWithValues: messages.map { ($0.identifier, $0) })
                                        return MessageStore(messages: messagesDict)
                                    } else {
                                        return MessageStore()
                                    }
                                }()
                            }
                            downloadGroup.leave()
                        }
                        
                        downloadGroup.notify(queue: DispatchQueue.main) {
                            completion(outerError, outerMessageStore)
                        }
                    } else {
                        completion(folderOperationError, outerMessageStore)
                    }
                }
            }
        })
    }
    
    func fetchFriendlyMailMessage(messageID: MessageID, completion: @escaping (Error?, BaseMessage?) -> ()) {
        let hourAgo = Calendar.current.date(
          byAdding: .hour,
          value: -1,
          to: Date())
        
        let recentSearchExpression = MCOIMAPSearchExpression.search(since: hourAgo)
        let headerSearchExpression = MCOIMAPSearchExpression.searchHeader("Message-ID", value: messageID)
        let combinedSearchExpression = MCOIMAPSearchExpression.searchAnd(recentSearchExpression, other: headerSearchExpression)
        
        let mailbox = Mailbox(name: "[Gmail]/All Mail", UIDValidity: 1)
        
        let searchOperation = imapSession.searchExpressionOperation(withFolder: mailbox.name, expression: combinedSearchExpression)
        
        searchOperation?.start { error, indexSet in
                var uids = [UInt64]()
                indexSet?.enumerate { uid in
                    uids.append(uid)
                }
                
                if let first = uids.first {
                    let uidWithMailbox = UIDWithMailbox(UID: first, mailbox: mailbox)
                    
                    fetchMessage(uidWithMailbox: uidWithMailbox) { fetchError, fetchedMessage in
                        completion(fetchError, fetchedMessage)
                    }
                } else {
                    completion(nil, nil)
                }
        }
    }
    
    func fetchMessage(uidWithMailbox: UIDWithMailbox, completion: @escaping (Error?, BaseMessage?) -> ()) {
        let operation = imapSession.fetchMessageOperation(withFolder: uidWithMailbox.mailbox.name, uid: UInt32(uidWithMailbox.UID))
        
        operation?.start({ error, data in
            if
                let data = data,
                let messageParser = MCOMessageParser(data: data),
                let header = MessageHeader(header: messageParser.header, mailbox: uidWithMailbox.mailbox)
            {
                DDLogDebug("MailController: fetchMessage: fetch succeeded")
                
                let message: BaseMessage = {
                    if
                        let fm = MessageFactory.createMessage(settings: self.settings, uidWithMailbox: uidWithMailbox, header: header, htmlBody: messageParser.htmlBodyRendering(), plainTextBody: messageParser.plainTextBodyRendering())
                    {
                        return fm
                    } else {
                        return Message(uidWithMailbox: uidWithMailbox, header: header, htmlBody: messageParser.htmlBodyRendering(), plainTextBody: messageParser.plainTextBodyRendering())
                    }
                }()
                completion(nil, message)
            } else {
                DDLogDebug("MailController: fetchMessage: fetch failed")
                completion(error, nil)
            }
        })
    }
    
}
