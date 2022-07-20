//
//  MessageFactoryTests.swift
//  friendly-mailTests
//
//  Created by Philip Loden on 9/1/21.
//

import XCTest
@testable import friendly_mail_ios
@testable import friendly_mail_core

class MessageFactoryTests: XCTestCase {
    
    func testCreatePostMessage() {
        let me = Address(name: "me", address: "me@me.com")!
        let subject = "Fm"
        let body = "This is a test post."
        let messageID = UIDWithMailbox(UID: UInt64.random(in: 1..<UInt64.max), mailbox: Mailbox(name: MailboxName.friendlyMail, UIDValidity: 1))
        let header = MessageHeader(sender: me, from: me, to: [me], replyTo: [me], subject: subject, date: Date(), extraHeaders: [:], messageID: "")

        let theme = (UIApplication.shared.delegate as! AppDelegate).appConfig.defaultTheme
        let settings = TestSettings(user: me, password: "", selectedTheme: theme)

        let message = MessageFactory.createMessage(settings: settings, uidWithMailbox: messageID, header: header, htmlBody: nil, plainTextBody: body) as? CreatePostingMessage ?? nil
        XCTAssertNotNil(message, "Message is not nil.")
        XCTAssertNotNil(message?.post)
        XCTAssert(message?.plainTextBody == body, "post body is not correct")
    }
    
    func testCreateAddFollowersMessage() throws {
        // Load email from file
        let path = Bundle(for: type(of: self )).path(forResource: "create_add_followers", ofType: "txt")!

        let uid: UInt64 = 1
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let theme = (UIApplication.shared.delegate as! AppDelegate).appConfig.defaultTheme
        let correctSettings = TestSettings(user: user, password: "", selectedTheme: theme)
        let correctMessage = TestHelpers.loadEmail(withPath: path, uid: uid, settings: correctSettings)
        
        XCTAssert(correctMessage is CreateAddFollowersMessage)
        
        let createAddFollowersMessage = correctMessage as! CreateAddFollowersMessage
        XCTAssert(createAddFollowersMessage.subscriptions.count == 1)
    }
    
    func testCreateInvitesMessage() throws {
        // Load email from file
        let path = Bundle(for: type(of: self )).path(forResource: "create_invite", ofType: "txt")!

        let uid: UInt64 = 1
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let theme = (UIApplication.shared.delegate as! AppDelegate).appConfig.defaultTheme
        let correctSettings = TestSettings(user: user, password: "", selectedTheme: theme)
        let correctMessage = TestHelpers.loadEmail(withPath: path, uid: uid, settings: correctSettings)
        
        XCTAssert(correctMessage is CreateInvitesMessage)
        
        let createInvitesMessage = correctMessage as! CreateInvitesMessage
        XCTAssert(createInvitesMessage.invites.count == 1)
    }
    
    func testNotificationsMessage() throws {
        // Load email from file
        let path = Bundle(for: type(of: self )).path(forResource: "notifications", ofType: "txt")!

        let uid: UInt64 = 1
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let theme = (UIApplication.shared.delegate as! AppDelegate).appConfig.defaultTheme
        let correctSettings = TestSettings(user: user, password: "", selectedTheme: theme)
        let correctMessage = TestHelpers.loadEmail(withPath: path, uid: uid, settings: correctSettings)
        
        XCTAssert(correctMessage is NotificationsMessage)
        
        if let correctMessage = correctMessage as? NotificationsMessage {
            XCTAssert(correctMessage.notifications.count == 1)
        }
    }
    
    func testExtractMessageID() throws {
        let mID = "4EC2D8F3-DD53-43CD-B38C-1AFDD5149C7C@gmail.com"
        let label = "Comment"
        let commentString = "Fm \(label):\(mID)"
        let extracted = MessageFactory.extractMessageID(withLabel: label, from: commentString)
        XCTAssert(extracted == mID)
        
    }
    
}
