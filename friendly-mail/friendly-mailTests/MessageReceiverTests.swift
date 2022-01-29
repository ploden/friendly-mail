//
//  MessageReceiverTests.swift
//  friendly-mailTests
//
//  Created by Philip Loden on 11/17/21.
//

import XCTest
@testable import friendly_mail
import MailCore

open class MessageReceiverTests: XCTestCase {

    /*
     A create post email exists. Was a corresponding CreatePostMessage object created?
     */
    func testCreatePostMessage() throws {
        let uid: UInt64 = 1
                        
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let settings = Settings(user: user, password: "", token: "")
         
        let path = Bundle(for: type(of: self )).path(forResource: "hello_world", ofType: "txt")!
        let message = TestHelpers.loadEmail(withPath: path, uid: uid, settings: settings)
        
        XCTAssertNotNil(message)
        XCTAssert(message is CreatePostMessage)
        
        let createPostMessage = message as! CreatePostMessage
        XCTAssertEqual("Hello World.", createPostMessage.post.articleBody)
    }

    /*
     A create invites email exists. Was a corresponding CreateInvitesMessage object created?
     */
    func testCreateInvitesMessage() throws {
        let uid: UInt64 = 1

        let incorrectUser = Address(name: "Phil Loden", address: "blah@blah.com")!
        let incorrectSettings = Settings(user: incorrectUser, password: "", token: "")
        
        // Load email from file
        let createInviteEmailPath = Bundle(for: type(of: self )).path(forResource: "create_invite", ofType: "txt")!
        let incorrectCreateInviteEmail = TestHelpers.loadEmail(withPath: createInviteEmailPath, uid: uid, settings: incorrectSettings)

        // Sender does not match account in settings, ergo should be no create invite message
        XCTAssertNotNil(incorrectCreateInviteEmail)
        XCTAssertFalse(incorrectCreateInviteEmail is CreateInvitesMessage)
        
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let correctSettings = Settings(user: user, password: "", token: "")
        let correctCreateInviteEmail = TestHelpers.loadEmail(withPath: createInviteEmailPath, uid: uid, settings: correctSettings)

        // Test for create invite message
        XCTAssertNotNil(correctCreateInviteEmail)
        XCTAssert(correctCreateInviteEmail is CreateInvitesMessage)
        
        // Test for invite
        let createInviteMessage = correctCreateInviteEmail as! CreateInvitesMessage
        let invite = createInviteMessage.invites.first!
        let expectedInvitee = Address(name: "", address: "ploden.postcards@gmail.com")
        XCTAssertEqual(expectedInvitee, invite.invitee)
        
        var messages = MessageStore()

        messages = messages.addingMessage(message: createInviteMessage, messageID: createInviteMessage.header.messageID)
        
        // Test for unsent invite
        let unsentInvites = MailController.unsentInvites(inviter: user, messages: messages)
        XCTAssert(unsentInvites.contains(invite))
        
        // Test that invite is not shown as sent
        let sentInvites = MailController.sentInvites(inviter: user, messages: messages)
        XCTAssert(sentInvites.contains(invite) == false)
                
        // Test that the message fields are populated correctly
        
        let settings = Settings(user: user, password: "", token: "")
        let provider = MailProvider(settings: settings, messages: messages)
        let results = MailController.processMail(sender: provider, receiver: provider, settings: settings, messages: messages)
        
        let expectedPlainTextBody =
        """
Phil Loden has invited you to their friendly-mail. Follow to receive their updates and photos:

Follow Daily: mailto:ploden@gmail.com?subject=Fm&body=Follow%20daily
Follow Weekly: mailto:ploden@gmail.com?subject=Fm&body=Follow%20weekly
Follow Monthly: mailto:ploden@gmail.com?subject=Fm&body=Follow%20monthly
Follow Realtime: mailto:ploden@gmail.com?subject=Fm&body=Follow%20realtime

friendly-mail, an open-source, email-based alternative to social networking

"""
        
        XCTAssert(results.drafts.count > 0)
        let match = results.drafts.first { $0.plainTextBody == expectedPlainTextBody }
        XCTAssertNotNil(match)
        XCTAssertNotNil(match!.subject)
    }

    /*
     A create subscription email exists. Was a corresponding CreateSubscriptionMessage object created?
     */
    func testCreateSubscriptionMessage() throws {
        // Load email from file
        let path = Bundle(for: type(of: self )).path(forResource: "follow_realtime", ofType: "txt")!

        let uid: UInt64 = 1
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let correctSettings = Settings(user: user, password: "", token: "")
        let correctMessage = TestHelpers.loadEmail(withPath: path, uid: uid, settings: correctSettings)
        
        // Test for create subscription message
        XCTAssertNotNil(correctMessage)
        XCTAssert(correctMessage is CreateSubscriptionMessage)
        
        // Test for subscription
        let createSubscriptionMessage = correctMessage as! CreateSubscriptionMessage
        let subscription = createSubscriptionMessage.subscription
        let expectedFollower = Address(name: "Phil Loden", address: "ploden.postcards@gmail.com")
        XCTAssertEqual(expectedFollower, subscription.follower)
        
        var messages = MessageStore()

        messages = messages.addingMessage(message: createSubscriptionMessage, messageID: createSubscriptionMessage.header.messageID)
        
        // Test for subscriptions
        let subscriptions = MailController.subscriptions(forAddress: Address(name: correctSettings.user.name, address: correctSettings.user.address)!, messages: messages)
        XCTAssert(subscriptions.contains(subscription))
    }
    
    static func loadCreatePostEmail(testCase: XCTestCase, uid: inout UInt64, settings: Settings, messages: inout MessageStore) {
        let createPostEmailPath = Bundle(for: type(of: testCase )).path(forResource: "hello_world", ofType: "txt")!
        let createPostMessage = TestHelpers.loadEmail(withPath: createPostEmailPath, uid: uid, settings: settings)
        uid += 1
        messages = messages.addingMessage(message: createPostMessage!, messageID: createPostMessage!.header.messageID)
    }
    
    static func loadCreateSubscriptionEmail(testCase: XCTestCase, uid: inout UInt64, settings: Settings, messages: inout MessageStore) {
        let followEmailPath = Bundle(for: type(of: testCase )).path(forResource: "follow_realtime", ofType: "txt")!
        let followMessage = TestHelpers.loadEmail(withPath: followEmailPath, uid: uid, settings: settings)
        uid += 1
        messages = messages.addingMessage(message: followMessage!, messageID: followMessage!.header.messageID)
    }
    
    static func loadCreateCommentEmail(testCase: XCTestCase, uid: inout UInt64, settings: Settings, messages: inout MessageStore) {
        let createPostEmailPath = Bundle(for: type(of: testCase )).path(forResource: "create_comment", ofType: "txt")!
        let createPostMessage = TestHelpers.loadEmail(withPath: createPostEmailPath, uid: uid, settings: settings)
        uid += 1
        messages = messages.addingMessage(message: createPostMessage!, messageID: createPostMessage!.header.messageID)
    }
    
    static func loadCreateLikeEmail(testCase: XCTestCase, uid: inout UInt64, settings: Settings, messages: inout MessageStore) {
        let createLikeEmailPath = Bundle(for: type(of: testCase )).path(forResource: "create_like", ofType: "txt")!
        let createLikeMessage = TestHelpers.loadEmail(withPath: createLikeEmailPath, uid: uid, settings: settings)
        uid += 1
        messages = messages.addingMessage(message: createLikeMessage!, messageID: createLikeMessage!.header.messageID)
    }
    
    /*
     Load a create subscription email and a create post email. Is an UpdateFollowerMessage sent?
     */
    func testCreateSubscriptionAndCreatePostAndUpdateFollower() throws {
        var uid: UInt64 = 1
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let settings = Settings(user: user, password: "", token: "")

        var messages = MessageStore()

        // Load create subscription email from file
        MessageReceiverTests.loadCreateSubscriptionEmail(testCase: self, uid: &uid, settings: settings, messages: &messages)
                
        // Load create post email from file
        MessageReceiverTests.loadCreatePostEmail(testCase: self, uid: &uid, settings: settings, messages: &messages)
        
        // Test for UpdateFollowerMessage
        let subscription = MailController.subscriptions(forAddress: settings.user, messages: messages).first!
        
        let unsent = MailController.unsentNewPostNotifications(settings: settings, messages: messages, for: subscription).first
        
        XCTAssert(unsent != nil)
        
        // Test that the message fields are populated correctly
        
        let provider = MailProvider(settings: settings, messages: messages)
        let results = MailController.processMail(sender: provider, receiver: provider, settings: settings, messages: messages)
        
        let expectedPlainTextBody =
        """
Phil Loden posted:

"Hello World."

Like: mailto:ploden@gmail.com?subject=Fm%20Like:61FD0524-97BD-4C61-A011-D613F3E63E05@gmail.com&body=👍🏻
Comment: mailto:ploden@gmail.com?subject=Fm%20Comment:61FD0524-97BD-4C61-A011-D613F3E63E05@gmail.com

friendly-mail, an open-source, email-based, alternative social network

"""
        
        let match = results.drafts.first { $0.plainTextBody == expectedPlainTextBody }
        XCTAssertNotNil(match)
        XCTAssertNotNil(match!.subject)
    }
    
    /*
     Load a create subscription email and a create post email and a create comment email. Is a notification email sent?
     */
    func testCreateSubscriptionAndCreatePostAndUpdateFollowerAndCreateComment() throws {
        var uid: UInt64 = 1
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let settings = Settings(user: user, password: "", token: "")

        var messages = MessageStore()

        // Load create subscription email from file
        MessageReceiverTests.loadCreateSubscriptionEmail(testCase: self, uid: &uid, settings: settings, messages: &messages)
                
        // Load create post email from file
        MessageReceiverTests.loadCreatePostEmail(testCase: self, uid: &uid, settings: settings, messages: &messages)
        
        // Load create comment email from file
        MessageReceiverTests.loadCreateCommentEmail(testCase: self, uid: &uid, settings: settings, messages: &messages)
        
        let comments = messages.allMessages.compactMap { $0 as? CreateCommentMessage }
        
        XCTAssert(comments.count > 0)
        
        // Test that the message fields are populated correctly
        
        let senderReceiver = TestSenderReceiver()
        senderReceiver.user = user
        senderReceiver.settings = settings
        
        let expectedPlainTextBody =
        """
Phil Loden commented on your post.

Phil Loden
\"Hello World.\"

Phil Loden
\"Hello back.\"

Like: mailto:ploden.postcards@gmail.com?subject=Fm%20Like:43ED17AA-EEF0-4A8C-B791-EB8C675B116E@gmail.com&body=👍🏻
Reply: mailto:ploden.postcards@gmail.com?subject=Fm%20Comment:43ED17AA-EEF0-4A8C-B791-EB8C675B116E@gmail.com

friendly-mail, an open-source, email-based, alternative social network

"""
   
        let provider = MailProvider(settings: settings, messages: messages)
        let results = MailController.processMail(sender: provider, receiver: provider, settings: settings, messages: messages)
        let match = results.drafts.first { $0.plainTextBody == expectedPlainTextBody }
        XCTAssertNotNil(match)
        XCTAssertNotNil(match!.subject)
    }
    
    /*
     Load a create subscription email and a create post email and a create like email. Is a notification email sent?
     */
    func testCreateSubscriptionAndCreatePostAndUpdateFollowerAndCreateLike() throws {
        var uid: UInt64 = 1
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let settings = Settings(user: user, password: "", token: "")

        var messages = MessageStore()

        // Load create subscription email from file
        MessageReceiverTests.loadCreateSubscriptionEmail(testCase: self, uid: &uid, settings: settings, messages: &messages)
                
        // Load create post email from file
        MessageReceiverTests.loadCreatePostEmail(testCase: self, uid: &uid, settings: settings, messages: &messages)
   
        let senderReceiver = TestSenderReceiver()
        senderReceiver.user = user
        senderReceiver.settings = settings
        
        let provider = MailProvider(settings: settings, messages: messages)
        
        let expectation = XCTestExpectation(description: "Wait for process mail.")
        MailController.getAndProcessAndSendMail(sender: senderReceiver, receiver: senderReceiver, settings: settings, messages: messages) { error, updatedMessages in
            // Load create like email from file
            messages = updatedMessages
            MessageReceiverTests.loadCreateLikeEmail(testCase: self, uid: &uid, settings: settings, messages: &messages)
                    
            // Test that the message fields are populated correctly
            
            let expectedPlainTextBody =
            """
    Phil Loden liked your post.

    Phil Loden:
    \"Hello World.\"

    Phil Loden:
    \"👍🏻\"

    friendly-mail, an open-source, email-based, alternative social network

    """
            
            let results = MailController.processMail(sender: provider, receiver: provider, settings: settings, messages: messages)
            let match = results.drafts.first { $0.plainTextBody == expectedPlainTextBody }
            XCTAssertNotNil(match)
            XCTAssertNotNil(match!.subject)
            XCTAssertNotNil(match?.friendlyMailHeaders)
            expectation.fulfill()
        }
        let _ = XCTWaiter.wait(for: [expectation], timeout: 2.0)
    }
}

class TestSenderReceiver: MessageSender, MessageReceiver {
    
    func moveMessageToInbox(message: BaseMessage, completion: @escaping (Error?) -> ()) {
        completion(nil)
    }
    
    func fetchFriendlyMailMessage(messageID: MessageID, completion: @escaping (Error?, BaseMessage?) -> ()) {
        completion(nil, nil)
    }
    
    func getMail(withMailbox mailbox: Mailbox, completion: @escaping (Error?, MessageStore) -> ()) {
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
    
