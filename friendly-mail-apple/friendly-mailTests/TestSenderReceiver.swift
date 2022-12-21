//
//  File.swift
//  friendly-mail-ios-Tests
//
//  Created by Philip Loden on 11/30/22.
//

import XCTest
@testable import friendly_mail_ios
@testable import friendly_mail_core

class TestSenderReceiver: MessageSender, MessageReceiver {
    var address: Address {
        get {
            return user
        }
    }
    
    func downloadFriendlyMailMessages(completion: @escaping (Error?, MessageStore?) -> ()) {
        
    }
    
    func moveMessageToInbox(message: BaseMessage, completion: @escaping (Error?) -> ()) {
        completion(nil)
    }
    
    func fetchFriendlyMailMessage(messageID: MessageID, completion: @escaping (Error?, BaseMessage?) -> ()) {
        completion(nil, nil)
    }
    
    func getMail(withMailbox mailbox: Mailbox, completion: @escaping (Error?, MessageStore?) -> ()) {
        if mailbox.name == MailboxName.friendlyMail {
            completion(nil, sentMessages)
            sentMessages = MessageStore()
        } else {
            completion(nil, MessageStore())
        }
    }
    
    var sentMessages = MessageStore()
    var user: Address!
    var settings: Settings!
    
    func fetchMessage(uidWithMailbox: UIDWithMailbox, completion: @escaping (Error?, BaseMessage?) -> ()) {
        completion(nil, nil)
    }
    
    /*
    func fetchMessages(withMailbox mailbox: Mailbox, uids: MCOIndexSet, completion: @escaping (Error?, MessageStore) -> ()) {
        if mailbox.name == MailboxName.friendlyMail {
            completion(nil, sentMessages)
            sentMessages.removeAll()
        } else {
            completion(nil, [:])
        }
    }
     */
    
    func sendDraft(draft: MessageDraft, completion: @escaping (Error?, MessageID?) -> ()) {
        sendMessage(to: draft.to, subject: draft.subject, htmlBody: draft.htmlBody, plainTextBody: draft.plainTextBody, friendlyMailHeaders: draft.friendlyMailHeaders, completion: completion)
    }
    
    func sendMessage(to: [Address], subject: String?, htmlBody: String?, plainTextBody: String, friendlyMailHeaders: [HeaderKeyValue]?, completion: @escaping (Error?, MessageID?) -> ()) {
        let extraHeaders: [String : String] = {
            if let friendlyMailHeaders = friendlyMailHeaders {
                let pairs = friendlyMailHeaders.compactMap { "\($0.key)=\($0.value)" }
                let joined = pairs.joined(separator: "; ")
                return [HeaderName.friendlymail.rawValue: joined]
            }
            return [:]
        }()
        
        let header = MessageHeader(sender: user, from: user!, to: to, replyTo: [user!], subject: subject, date: Date.now, extraHeaders: extraHeaders, messageID: NSUUID().uuidString.lowercased())
        
        let uidWithMailbox = UIDWithMailbox(UID: 1, mailbox: Mailbox(name: .friendlyMail, UIDValidity: 0))
        let message = MessageFactory.createMessage(account: nil,
                                                   uidWithMailbox: uidWithMailbox,
                                                   header: header!,
                                                   htmlBody: htmlBody,
                                                   friendlyMailData: MailProvider.friendlyMailData(for: htmlBody),
                                                   plainTextBody: plainTextBody,
                                                   attachments: nil,
                                                   logger: nil)
        sentMessages = sentMessages.addingMessage(message: message!, messageID: message!.header.messageID)
        
        completion(nil, message!.header.messageID)
    }
}
    
