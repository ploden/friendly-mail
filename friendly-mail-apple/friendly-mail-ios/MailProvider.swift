//
//  MailProvider.swift
//  friendly-mail
//
//  Created by Philip Loden on 12/8/21.
//

import Foundation
import UIKit
import friendly_mail_core
import SwiftSoup

@objc public protocol MailProviderObserver {
    @objc func mailProviderDidChange(_ notification: Foundation.Notification)
}

public extension Foundation.Notification.Name {
    static let mailProviderDidChange = Foundation.Notification.Name("FM_mailProviderDidChange")
}

public struct MailProvider {
    public let settings: AppleSettings
    public private(set) var messages: MessageStore
    /*
    public var account: FriendlyMailAccount? {
        let message = messages.allMessages.first { $0 is CreateAccountMessage }
        
        if let message = message as? CreateAccountSucceededCommandResultMessage {
            return message.account
        }
        return nil
    }
     */
    public var preferences: Preferences? {
        return Preferences(selectedThemeID: "")
    }
    private let imapSession: MCOIMAPSession
    
    public func new(withSettings: Settings, postNotification: Bool) -> MailProvider {
        let newWith = MailProvider(settings: settings, messages: self.messages)
        if postNotification {
            NotificationCenter.default.post(name: Foundation.Notification.Name.mailProviderDidChange, object: newWith)
        }
        return newWith
    }
    
    /*
    public func new(mergingMessages messages: [MessageID : BaseMessage], postNotification: Bool) -> MailProvider {
        var newWith = self
        let newMessages = self.messages.merging(messages: messages)
        newWith.messages = newMessages
        if postNotification {
            NotificationCenter.default.post(name: Foundation.Notification.Name.mailProviderDidChange, object: newWith)
        }
        return newWith
    }
     */
    
    public func new(mergingMessageStores messageStore: MessageStore, postNotification: Bool) -> MailProvider {
        var newWith = self
        let newMessages = self.messages.merging(messageStore: messageStore)
        newWith.messages = newMessages
        if postNotification {
            NotificationCenter.default.post(name: Foundation.Notification.Name.mailProviderDidChange, object: newWith)
        }
        return newWith
    }
    
    public init(settings: AppleSettings, messages: MessageStore) {
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
    
    /*
    public func sendDraft(draft: MessageDraft, completion: @escaping (Result<MessageID, Error>) -> Void) {
        sendMessage(to: draft.to, subject: draft.subject, htmlBody: draft.htmlBody, plainTextBody: draft.plainTextBody, friendlyMailHeaders: draft.friendlyMailHeaders, completion: completion)
    }
    
    public func sendDraft(draft: MessageDraft) async throws -> MessageID {
        return await withCheckedContinuation { continuation in
            sendDraft(draft: draft) { result in
                continuation.resume(returning: result)
            }
        }
    }
     */
    
    public func sendDraft(draft: AnyMessageDraft) async throws -> MessageID {
        return try await withCheckedThrowingContinuation { continuation in
            sendMessage(to: draft.to,
                        subject: draft.subject,
                        htmlBody: draft.htmlBody,
                        plainTextBody: draft.plainTextBody,
                        friendlyMailHeaders: draft.friendlyMailHeaders)
            { result in
                switch result {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func sendDraft(draft: MessageDraft, completion: @escaping (Result<MessageID, Error>) -> Void) {
        Task {
            do {
                let result = try await sendDraft(draft: draft)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func sendMessage(to: [Address], subject: String?, htmlBody: String?, plainTextBody: String, friendlyMailHeaders: [HeaderKeyValue]?, completion: @escaping (Result<MessageID, Error>) -> Void) {
        guard settings.isValid else {
            completion(.failure(NSError(domain: "fm", code: 1, userInfo: [:])))
            return
        }
        
        settings.authState?.performAction(freshTokens: { accessToken, idToken, freshTokensError in
            guard let accessToken = accessToken else {
                //completion(.failure(freshTokensError))
                completion(.failure(NSError(domain: "fm", code: 1, userInfo: [:])))
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
                if error != nil {
                    //DDLogDebug("MailController: sendMessage: send failed with error: \(error)")
                } else {
                    //DDLogDebug("MailController: sendMessage: send succeeded")
                }
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(builder.header.messageID))
                }
                //completion(error, error == nil ? builder.header.messageID : nil)
            }
        })
    }
    
    public func moveMessageToInbox(message: AnyBaseMessage, completion: @escaping (Error?) -> ()) {
        let requestKind: MCOIMAPStoreFlagsRequestKind = .add
        let labels = ["\\Inbox", MailboxName.friendlyMail]
        
        let operation = imapSession.storeLabelsOperation(withFolder: message.uidWithMailbox.mailbox.name, uids: MCOIndexSet(index: message.uidWithMailbox.UID), kind: requestKind, labels: labels)
        operation?.start({ error in
                completion(error)
        })
    }
    
    public static func addObserver(forSettings anObserver: SettingsObserver) {
        NotificationCenter.default.addObserver(anObserver as Any, selector: #selector(MailProviderObserver.mailProviderDidChange(_:)), name: Foundation.Notification.Name.mailProviderDidChange, object: nil)
    }
    
    static func removeObserver(forSettings anObserver: SettingsObserver?) {
        NotificationCenter.default.removeObserver(anObserver as Any, name: .settingsDidChange, object: nil)
    }
}

extension MailProvider: MessageReceiver {

    public var address: Address {
        get {
            return Address(address: imapSession.username)
        }
    }
    
    public func downloadFriendlyMailMessages(completion: @escaping (Error?, MessageStore?) -> ()) {
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
            
            DispatchQueue.global(qos: .default).async {
                var outerError: Error? = nil
                var outerMessageStore: MessageStore? = nil
                                               
                let location: UInt64 = {
                    let max = messages.allMessages.compactMap { $0.uidWithMailbox.UID }.max()
                    return max ?? 1
                }()
                
                let indexSet = MCOIndexSet(range: MCORange(location: location, length: UInt64.max))
                let fetchOperation: MCOIMAPFetchMessagesOperation = imapSession.fetchMessagesByUIDOperation(withFolder: .friendlyMail, requestKind: requestKind, uids: indexSet)
                
                let downloadGroup = DispatchGroup()
                
                let mailbox = Mailbox(name: .friendlyMail, UIDValidity: 0)
                
                downloadGroup.enter()
                fetchOperation.start { fetchMessagesError, fetchedMessages, vanishedMessages in
                    if let fetchMessagesError = fetchMessagesError {
                        //DDLogDebug("MailController: getMail: error: \(String(describing: fetchMessagesError))")
                        outerError = fetchMessagesError
                    } else {
                        let messages: [AnyBaseMessage]? = fetchedMessages?.compactMap {
                            if let header = MessageHeader(header: $0.header, mailbox: mailbox) {
                                let messageID = UIDWithMailbox(UID: UInt64($0.uid), mailbox: mailbox)
                                
                                return MessageFactory.createMessage(account: self.messages.account, uidWithMailbox: messageID, header: header, htmlBody: nil, friendlyMailData: nil, plainTextBody: nil, attachments: MailProvider.attachments(forAny: $0), logger: nil)
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
            }
        })
    }
    
    public func getMail(withMailbox mailbox: Mailbox, completion: @escaping (Error?, MessageStore?) -> ()) {
        guard settings.isValid else {
            completion(NSError(domain: "fm", code: 1, userInfo: [:]), nil)
            return
        }
        
        let logger = (UIApplication.shared.delegate as! AppDelegate).logger
        
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
                                //DDLogDebug("MailController: getMail: error: \(String(describing: fetchMessagesError))")
                                outerError = fetchMessagesError
                            } else {
                                let messages: [AnyBaseMessage]? = fetchedMessages?.compactMap {
                                    if let header = MessageHeader(header: $0.header, mailbox: mailbox) {
                                        let messageID = UIDWithMailbox(UID: UInt64($0.uid), mailbox: mailbox)
                                        
                                        //let address = Address(name: nil, address: imapSession.username)!
                                        
                                        return MessageFactory.createMessage(account: self.messages.account,
                                                                            uidWithMailbox: messageID,
                                                                            header: header,
                                                                            htmlBody: nil,
                                                                            friendlyMailData: nil,
                                                                            plainTextBody: nil,
                                                                            attachments: nil,
                                                                            logger: nil)
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
    
    public func fetchFriendlyMailMessage(messageID: MessageID, completion: @escaping (Error?, AnyBaseMessage?) -> ()) {
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
    
    public func fetchMessage(uidWithMailbox: UIDWithMailbox, completion: @escaping (Error?, AnyBaseMessage?) -> ()) {
        let operation = imapSession.fetchMessageOperation(withFolder: uidWithMailbox.mailbox.name, uid: UInt32(uidWithMailbox.UID))
        
        operation?.start({ error, data in
            if
                let data = data,
                let messageParser = MCOMessageParser(data: data),
                let header = MessageHeader(header: messageParser.header, mailbox: uidWithMailbox.mailbox)
            {                
                let message: AnyBaseMessage = {
                    let htmlBody = messageParser.htmlBodyRendering()
                    
                    let accountUsername = imapSession.username
                    
                    let address = Address(name: nil, address: accountUsername)!
                    
                    if let fm = MessageFactory.createMessage(account: self.messages.account,
                                                             uidWithMailbox: uidWithMailbox,
                                                             header: header,
                                                             htmlBody: htmlBody,
                                                             friendlyMailData: MailProvider.friendlyMailData(for: htmlBody),
                                                             plainTextBody: messageParser.plainTextBodyRendering(),
                                                             attachments: MailProvider.attachments(forAny: messageParser),
                                                             logger: nil)
                    {
                        return fm
                    } else {
                        return Message(uidWithMailbox: uidWithMailbox,
                                       header: header,
                                       htmlBody: messageParser.htmlBodyRendering(),
                                       plainTextBody: messageParser.plainTextBodyRendering(),
                                       attachments: MailProvider.attachments(forAny: messageParser))                    }
                }()
                completion(nil, message)
            } else {
                //DDLogDebug("MailController: fetchMessage: fetch failed")
                completion(error, nil)
            }
        })
    }
    
    public static func attachments(forAny any: Any) -> [Attachment]? {
        
        func handleMultipart(multipart: MCOMultipart, attachments: inout [Attachment]) {
            multipart.parts.forEach { part in
                if let part = part as? MCOAttachment {
                    let attachment = Attachment(mimeType: part.mimeType, data: part.data, filename: part.filename)
                    attachments.append(attachment)
                } else if let anotherMultipart = part as? MCOMultipart {
                    handleMultipart(multipart: anotherMultipart, attachments: &attachments)
                }
            }
        }
        
        if
            let parser = any as? MCOMessageParser,
            let multipart = parser.mainPart() as? MCOMultipart
        {
            var attachments = [Attachment]()
            handleMultipart(multipart: multipart, attachments: &attachments)
            return attachments
        } else if let part = any as? MCOIMAPPart {
            return nil
        }
        return nil
    }
  
    static func friendlyMailData(for htmlBody: String?) -> String? {
        if
            let htmlBody = htmlBody,
            let doc: Document = try? SwiftSoup.parse(htmlBody),
            let script = try? doc.head()?.select("script").first { $0.id() == "friendly-mail-data" }
        {
            return try? script.html()
        }
        return nil
    }
}
