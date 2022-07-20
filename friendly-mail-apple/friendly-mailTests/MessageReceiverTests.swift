//
//  MessageReceiverTests.swift
//  friendly-mailTests
//
//  Created by Philip Loden on 11/17/21.
//

import XCTest
@testable import friendly_mail_ios
@testable import friendly_mail_core
//import MailCore

open class MessageReceiverTests: XCTestCase {
    
    static func loadCreatePostEmail(testCase: XCTestCase, uid: inout UInt64, settings: Settings, messages: inout MessageStore) {
        let createPostEmailPath = Bundle(for: type(of: testCase )).path(forResource: "hello_world", ofType: "txt")!
        TestHelpers.loadEmail(withPath: createPostEmailPath, uid: &uid, settings: settings, messages: &messages)
    }
    
    static func loadCreateSubscriptionEmail(testCase: XCTestCase, uid: inout UInt64, settings: Settings, messages: inout MessageStore) {
        let followEmailPath = Bundle(for: type(of: testCase )).path(forResource: "follow_realtime", ofType: "txt")!
        TestHelpers.loadEmail(withPath: followEmailPath, uid: &uid, settings: settings, messages: &messages)
    }

    static func loadCreateInvitesEmail(testCase: XCTestCase, uid: inout UInt64, settings: Settings, messages: inout MessageStore) {
        let followEmailPath = Bundle(for: type(of: testCase )).path(forResource: "create_invite", ofType: "txt")!
        TestHelpers.loadEmail(withPath: followEmailPath, uid: &uid, settings: settings, messages: &messages)
    }
    
    static func loadCreateCommentEmail(testCase: XCTestCase, uid: inout UInt64, settings: Settings, messages: inout MessageStore) {
        let createPostEmailPath = Bundle(for: type(of: testCase )).path(forResource: "create_comment", ofType: "txt")!
        TestHelpers.loadEmail(withPath: createPostEmailPath, uid: &uid, settings: settings, messages: &messages)
    }
    
    static func loadCreateLikeEmail(testCase: XCTestCase, uid: inout UInt64, settings: Settings, messages: inout MessageStore) {
        let createLikeEmailPath = Bundle(for: type(of: testCase )).path(forResource: "create_like", ofType: "txt")!
        TestHelpers.loadEmail(withPath: createLikeEmailPath, uid: &uid, settings: settings, messages: &messages)
    }
}

class TestSenderReceiver: MessageSender, MessageReceiver {
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
        let message = MessageFactory.createMessage(settings: settings, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
        sentMessages = sentMessages.addingMessage(message: message!, messageID: message!.header.messageID)
        
        completion(nil, message!.header.messageID)
    }
}
    
