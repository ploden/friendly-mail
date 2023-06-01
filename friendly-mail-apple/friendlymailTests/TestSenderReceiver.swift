//
//  File.swift
//  friendlymail-ios-Tests
//
//  Created by Philip Loden on 11/30/22.
//

import XCTest
@testable import friendlymail_ios
@testable import friendlymail_core

class TestSenderReceiver: MessageSender, MessageReceiver {
    var address: EmailAddress {
        get {
            return user
        }
    }
    
    func downloadFriendlyMailMessages(completion: @escaping (Error?, MessageStore?) -> ()) {
        
    }
    
    func moveMessageToInbox(message: any AnyBaseMessage, completion: @escaping (Error?) -> ()) {
        completion(nil)
    }
    
    func fetchFriendlyMailMessage(messageID: MessageID, completion: @escaping (Error?, (any AnyBaseMessage)?) -> ()) {
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
    var user: EmailAddress!
    var account: FriendlyMailUser?
    var settings: Settings!
    
    func fetchMessage(uidWithMailbox: UIDWithMailbox, completion: @escaping (Error?, (any AnyBaseMessage)?) -> ()) {
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
    
    func sendDraft(draft: AnyMessageDraft) async throws -> MessageID {
        return try await withCheckedThrowingContinuation { continuation in
            sendMessage(to: draft.to,
                        subject: draft.subject,
                        htmlBody: draft.htmlBody,
                        plainTextBody: draft.plainTextBody,
                        friendlyMailHeaders: draft.friendlyMailHeaders, logger: nil)
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

    func sendDraft(draft: MessageDraft, completion: @escaping (Result<MessageID, Error>) -> Void) {
        Task {
            do {
                let result = try await sendDraft(draft: draft)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func sendMessage(to: [EmailAddress], subject: String?, htmlBody: String?, plainTextBody: String, friendlyMailHeaders: [HeaderKeyValue]?, logger: Logger?, completion: @escaping (Result<MessageID, Error>) -> Void) {
        let extraHeaders: [String : String] = {
            if let friendlyMailHeaders = friendlyMailHeaders {
                let pairs = friendlyMailHeaders.compactMap { "\($0.key)=\($0.value)" }
                let joined = pairs.joined(separator: "; ")
                return [HeaderName.friendlymail.rawValue: joined]
            }
            return [:]
        }()
        
        let header = MessageHeader(host: user, from: user!, to: to, replyTo: [user!], subject: subject, date: Date.now, extraHeaders: extraHeaders, messageID: NSUUID().uuidString.lowercased())
        
        let uidWithMailbox = UIDWithMailbox(UID: 1, mailbox: Mailbox(name: .friendlyMail, UIDValidity: 0))
        let message = MessageFactory.createMessage(account: account,
                                                   uidWithMailbox: uidWithMailbox,
                                                   header: header!,
                                                   htmlBody: htmlBody,
                                                   friendlyMailData: MailProvider.friendlyMailData(for: htmlBody),
                                                   plainTextBody: plainTextBody,
                                                   attachments: nil,
                                                   logger: nil)
        sentMessages = sentMessages.addingMessage(message: message!, messageID: message!.header.messageID)
        
        completion(.success(message!.header.messageID))
    }
}

