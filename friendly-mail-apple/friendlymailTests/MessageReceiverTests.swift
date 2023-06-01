//
//  MessageReceiverTests.swift
//  friendlymailTests
//
//  Created by Philip Loden on 11/17/21.
//

import XCTest
@testable import friendlymail_ios
@testable import friendlymail_core
//import MailCore

open class MessageReceiverTests: XCTestCase {

    static func loadCreateAccountEmail(testCase: XCTestCase, uid: inout UInt64, messages: inout MessageStore, host: EmailAddress) -> (any AnyBaseMessage)? {
        let createPostEmailPath = Bundle(for: type(of: testCase )).path(forResource: "create_command_create_account", ofType: "txt")!
        return TestHelpers.loadEmail(host: host, account: nil, withPath: createPostEmailPath, uid: &uid, messages: &messages)
    }

    static func loadCreateAccountEmailAndSendResponse(config: AppConfig,
                                                      sender: MessageSender,
                                                      receiver: MessageReceiver,
                                                      testCase: XCTestCase,
                                                      uid: inout UInt64,
                                                      messages: inout MessageStore) async
    {
        let _ = MessageReceiverTests.loadCreateAccountEmail(testCase: testCase, uid: &uid, messages: &messages, host: receiver.address)
        await TestHelpers.processMailAndSend(config: config, sender: sender, receiver: receiver, testCase: testCase, messages: &messages)
    }
    
    static func loadCreatePostEmail(testCase: XCTestCase, uid: inout UInt64, provider: inout MailProvider) -> (any AnyBaseMessage)? {
        let createPostEmailPath = Bundle(for: type(of: testCase )).path(forResource: "hello_world", ofType: "txt")!
        if let account = provider.messages.hostUser {
            return TestHelpers.loadEmail(account: account, withPath: createPostEmailPath, uid: &uid, provider: &provider)
        } else {
            var inoutMessages: MessageStore! = provider.messages
            let message = TestHelpers.loadEmail(host: provider.settings.user, account: nil, withPath: createPostEmailPath, uid: &uid, messages: &inoutMessages)
            provider = provider.new(mergingMessageStore: inoutMessages, postNotification: false)
            inoutMessages = nil
            return message
        }
    }
    
    static func loadCreateAddFollowersEmail(testCase: XCTestCase, uid: inout UInt64, provider: inout MailProvider) -> (any AnyBaseMessage)? {
        let followEmailPath = Bundle(for: type(of: testCase )).path(forResource: "create_add_followers", ofType: "txt")!
        return TestHelpers.loadEmail(account: provider.messages.hostUser!, withPath: followEmailPath, uid: &uid, provider: &provider)
    }
    
    static func loadCreateAddFollowersEmail(testCase: XCTestCase, uid: inout UInt64, account: FriendlyMailUser, messages: inout MessageStore) -> (any AnyBaseMessage)? {
        let followEmailPath = Bundle(for: type(of: testCase )).path(forResource: "create_add_followers", ofType: "txt")!
        return TestHelpers.loadEmail(host: account.email, account: account, withPath: followEmailPath, uid: &uid, messages: &messages)
    }

    static func loadCreateInvitesEmail(testCase: XCTestCase, uid: inout UInt64, account: FriendlyMailUser, messages: inout MessageStore) -> (any AnyBaseMessage)? {
        let followEmailPath = Bundle(for: type(of: testCase )).path(forResource: "create_invite", ofType: "txt")!
        return TestHelpers.loadEmail(host: account.email, account: account, withPath: followEmailPath, uid: &uid, messages: &messages)
    }
    
    static func loadCreateCommentEmail(testCase: XCTestCase, uid: inout UInt64, provider: inout MailProvider) -> (any AnyBaseMessage)? {
        let createCommentEmailPath = Bundle(for: type(of: testCase )).path(forResource: "create_comment", ofType: "txt")!
        return TestHelpers.loadEmail(account: provider.messages.hostUser!, withPath: createCommentEmailPath, uid: &uid, provider: &provider)
    }
    
    static func loadCreateCommentEmail(testCase: XCTestCase, uid: inout UInt64, account: FriendlyMailUser, messages: inout MessageStore) -> (any AnyBaseMessage)? {
        let createCommentEmailPath = Bundle(for: type(of: testCase )).path(forResource: "create_comment", ofType: "txt")!
        return TestHelpers.loadEmail(host: account.email, account: account, withPath: createCommentEmailPath, uid: &uid, messages: &messages)
    }
    
    static func loadCreateLikeEmail(testCase: XCTestCase, uid: inout UInt64, provider: inout MailProvider) -> (any AnyBaseMessage)? {
        let createLikeEmailPath = Bundle(for: type(of: testCase )).path(forResource: "create_like", ofType: "txt")!
        return TestHelpers.loadEmail(account: provider.messages.hostUser!, withPath: createLikeEmailPath, uid: &uid, provider: &provider)
    }
}
