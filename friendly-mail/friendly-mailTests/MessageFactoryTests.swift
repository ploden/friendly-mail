//
//  MessageFactoryTests.swift
//  friendly-mailTests
//
//  Created by Philip Loden on 9/1/21.
//

import XCTest
@testable import friendly_mail

class MessageFactoryTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCreatePostMessage() {
        let me = Address(name: "me", address: "me@me.com")!
        let subject = "Fm"
        let body = "This is a test post."
        let messageID = UIDWithMailbox(UID: UInt64.random(in: 1..<UInt64.max), mailbox: Mailbox(name: MailboxName.friendlyMail, UIDValidity: 1))
        let header = MessageHeader(sender: me, from: me, to: [me], replyTo: [me], subject: subject, date: Date(), extraHeaders: [:], messageID: "")

        let settings = Settings(user: me, password: "", token: "")

        let message = MessageFactory.createMessage(settings: settings, uidWithMailbox: messageID, header: header, htmlBody: nil, plainTextBody: body) as? CreatePostMessage ?? nil
        XCTAssertNotNil(message, "Message is not nil.")
        XCTAssertNotNil(message?.post)
        XCTAssert(message?.plainTextBody == body, "post body is not correct")
    }
    
    func testCreateInvitesMessage() throws {
        // Load email from file
        let path = Bundle(for: type(of: self )).path(forResource: "create_invite", ofType: "txt")!

        let uid: UInt64 = 1
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let correctSettings = Settings(user: user, password: "", token: "")
        let correctMessage = TestHelpers.loadEmail(withPath: path, uid: uid, settings: correctSettings)
        
        XCTAssert(correctMessage is CreateInvitesMessage)
        
        let createInvitesMessage = correctMessage as! CreateInvitesMessage
        XCTAssert(createInvitesMessage.invites.count == 2)
    }
    
    func testNotificationsMessage() throws {
        // Load email from file
        let path = Bundle(for: type(of: self )).path(forResource: "notifications", ofType: "txt")!

        let uid: UInt64 = 1
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let correctSettings = Settings(user: user, password: "", token: "")
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
