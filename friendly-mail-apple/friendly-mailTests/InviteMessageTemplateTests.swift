//
//  InviteMessageTemplateTests.swift
//  friendly-mailTests
//
//  Created by Philip Loden on 3/25/22.
//

import XCTest
@testable import friendly_mail_core
@testable import friendly_mail_ios

class InviteMessageTemplateTests: XCTestCase {

    func testCreateInvitesMessage() throws {
        let uid: UInt64 = 1

        let theme = (UIApplication.shared.delegate as! AppDelegate).appConfig.defaultTheme
        
        // Load email from file
        let createInviteEmailPath = Bundle(for: type(of: self )).path(forResource: "create_invite", ofType: "txt")!

        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let settings = AppleSettings(user: user, selectedTheme: theme)
        let createInviteMessage = TestHelpers.loadEmail(withPath: createInviteEmailPath, uid: uid, settings: settings)!

        var messages = MessageStore()

        messages = messages.addingMessage(message: createInviteMessage, messageID: createInviteMessage.header.messageID)
                
        // Test that the message fields are populated correctly
        
        let provider = MailProvider(settings: settings, messages: messages)
        let results = MailController.processMail(sender: provider, receiver: provider, settings: settings, messages: messages)
        
        let plainTextPath = Bundle(for: type(of: self )).path(forResource: "expected_plain_text", ofType: "txt", inDirectory: "InviteMessageTemplateTests")!
        let expectedPlainTextBody = try! String(contentsOf: URL(fileURLWithPath: plainTextPath))
  
        XCTAssert(results.drafts.count == 1)
        let match = results.drafts.first!
        XCTAssertNotNil(match)
        XCTAssert(match.plainTextBody == expectedPlainTextBody)
        
        let filename = "invite_message.html"
        if let path = TestHelpers.writeToTmpDir(string: match.htmlBody!, filename: filename) {
            print(path)
        }
        
        let htmlPath = Bundle(for: type(of: self )).path(forResource: "expected_html", ofType: "html", inDirectory: "InviteMessageTemplateTests")!
        let expectedHTML = try! String(contentsOf: URL(fileURLWithPath: htmlPath))
        print(match.htmlBody!)
        
        XCTAssert(match.htmlBody == expectedHTML)
    }
    
}
