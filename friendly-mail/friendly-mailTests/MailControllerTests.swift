//
//  MailControllerTests.swift
//  friendly-mailTests
//
//  Created by Philip Loden on 9/2/21.
//

import XCTest
@testable import friendly_mail

class MailControllerTests: XCTestCase {

    /*
    /*
     Story: user creates a new post. Follower notifications are created. TODO: test contents
     */
    func testNewPostFollowerNotifications() {
        let myAddress = TestHelpers.testAddress()
        
        let sub1 = Address(name: "Sub One", address: "sub1@gmail.com")!
        let settings = Settings(username: "", password: "", name: "", token: "")
        let messages = MessageStore()
        XCTAssert(MailController.newPostFollowerNotifications(settings: settings, messages: messages).count == 0, "num should be 0")
        XCTAssert(MailController.sentNewPostFollowerNotifications(settings: settings, messages: messages).count == 0, "num should be 0")
        XCTAssert(MailController.unsentNewPostFollowerNotifications(settings: settings, messages: messages).count == 0, "num should be 0")

        let postMessage = TestHelpers.testCreatePostMessage(author: myAddress)
        
        let messagesWithPostMessage = [postMessage.messageID: postMessage]
                
        XCTAssert(MailController.newPostFollowerNotifications(settings: settings, messages: messagesWithPostMessage).count == 1, "num should be 1")
        XCTAssert(MailController.sentNewPostFollowerNotifications(settings: settings, messages: messagesWithPostMessage).count == 0, "num should be 0")
        XCTAssert(MailController.unsentNewPostFollowerNotifications(settings: settings, messages: messagesWithPostMessage).count == 1, "num should be 1")
        
        // after the notification has been sent
        let notificationMessage = TestHelpers.testPostNotificationMessage(postAuthor: myAddress, postMessageID: postMessage.messageID, follower: sub1)
        
        let messagesWithPostAndNotificationMessages = [
            postMessage.messageID: postMessage,
            notificationMessage.messageID: notificationMessage
        ]

        XCTAssert(MailController.newPostFollowerNotifications(settings: settings, messages: messagesWithPostAndNotificationMessages).count == 1, "num should be 1")
        XCTAssert(MailController.sentNewPostFollowerNotifications(settings: settings, messages: messagesWithPostAndNotificationMessages).count == 1, "num should be 1")
        XCTAssert(MailController.unsentNewPostFollowerNotifications(settings: settings, messages: messagesWithPostAndNotificationMessages).count == 0, "num should be 0")
    }

    /*
     Story: user creates post. Follower likes post. User is notified of like. 
     */
    func testReceivedLikesSelfNotifications() {
        let myAddress = TestHelpers.testAddress()

        // create the message that creates the post
        let postMessage = TestHelpers.testCreatePostMessage(author: myAddress)
        
        // create follower
        let sub1 = Address(name: "Sub One", address: "sub1@gmail.com")!
        let settings = Settings(username: "", password: "", name: "", token: "")
        
        let messagesWithPostMessage = [postMessage.messageID: postMessage]

        XCTAssert(MailController.newPostFollowerNotifications(settings: settings, messages: messagesWithPostMessage).count == 1, "num should be 1")
        XCTAssert(MailController.sentNewPostFollowerNotifications(settings: settings, messages: messagesWithPostMessage).count == 0, "num should be 0")
        XCTAssert(MailController.unsentNewPostFollowerNotifications(settings: settings, messages: messagesWithPostMessage).count == 1, "num should be 1")
        
        
        //let postNotificationMessage = TestHelpers.test
        
        //let messagesWithPostMessage = [postMessage.messageID: postMessage]
    }
    */
    
    func testNewPostFollowerNotifications() throws {
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
            
            let newsFeed = MailController.newsFeedNotifications(settings: settings, messages: messages)
            XCTAssert(newsFeed.count > 0)
            
            let results = MailController.processMail(sender: provider, receiver: provider, settings: settings, messages: messages)
            let match = results.drafts.first { $0.plainTextBody == expectedPlainTextBody }
            XCTAssertNotNil(match)
            XCTAssertNotNil(match!.subject)
            expectation.fulfill()
        }
        let _ = XCTWaiter.wait(for: [expectation], timeout: 2.0)
    }
}
