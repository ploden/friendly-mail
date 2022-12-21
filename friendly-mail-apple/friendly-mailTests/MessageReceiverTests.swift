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

    static func loadCreateAccountEmail(testCase: XCTestCase, uid: inout UInt64, messages: inout MessageStore) {
        let createPostEmailPath = Bundle(for: type(of: testCase )).path(forResource: "create_command_create_account", ofType: "txt")!
        TestHelpers.loadEmail(account: nil, withPath: createPostEmailPath, uid: &uid, messages: &messages)
    }

    static func loadCreateAccountEmailAndSendResponse(config: AppConfig,
                                                      sender: MessageSender,
                                                      receiver: MessageReceiver,
                                                      testCase: XCTestCase,
                                                      uid: inout UInt64,
                                                      messages: inout MessageStore)
    {
        MessageReceiverTests.loadCreateAccountEmail(testCase: testCase, uid: &uid, messages: &messages)
        TestHelpers.processMailAndSend(config: config, sender: sender, receiver: receiver, testCase: testCase, messages: &messages)
    }
    
    static func loadCreatePostEmail(testCase: XCTestCase, uid: inout UInt64, account: FriendlyMailAccount, messages: inout MessageStore) {
        let createPostEmailPath = Bundle(for: type(of: testCase )).path(forResource: "hello_world", ofType: "txt")!
        TestHelpers.loadEmail(account: account, withPath: createPostEmailPath, uid: &uid, messages: &messages)
    }
    
    static func loadCreateSubscriptionEmail(testCase: XCTestCase, uid: inout UInt64, account: FriendlyMailAccount, messages: inout MessageStore) {
        let followEmailPath = Bundle(for: type(of: testCase )).path(forResource: "follow_realtime", ofType: "txt")!
        TestHelpers.loadEmail(account: account, withPath: followEmailPath, uid: &uid, messages: &messages)
    }

    static func loadCreateInvitesEmail(testCase: XCTestCase, uid: inout UInt64, account: FriendlyMailAccount, messages: inout MessageStore) {
        let followEmailPath = Bundle(for: type(of: testCase )).path(forResource: "create_invite", ofType: "txt")!
        TestHelpers.loadEmail(account: account, withPath: followEmailPath, uid: &uid, messages: &messages)
    }
    
    static func loadCreateCommentEmail(testCase: XCTestCase, uid: inout UInt64, account: FriendlyMailAccount, messages: inout MessageStore) {
        let createPostEmailPath = Bundle(for: type(of: testCase )).path(forResource: "create_comment", ofType: "txt")!
        TestHelpers.loadEmail(account: account, withPath: createPostEmailPath, uid: &uid, messages: &messages)
    }
    
    static func loadCreateLikeEmail(testCase: XCTestCase, uid: inout UInt64, account: FriendlyMailAccount, messages: inout MessageStore) {
        let createLikeEmailPath = Bundle(for: type(of: testCase )).path(forResource: "create_like", ofType: "txt")!
        TestHelpers.loadEmail(account: account, withPath: createLikeEmailPath, uid: &uid, messages: &messages)
    }
}
