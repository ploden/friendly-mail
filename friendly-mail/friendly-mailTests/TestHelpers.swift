//
//  TestHelpers.swift
//  friendly-mailTests
//
//  Created by Philip Loden on 9/8/21.
//

import Foundation
@testable import friendly_mail
import MailCore

extension String {
    static func random(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}

class TestHelpers {
    
    static func testAddress() -> Address {
        let name = String.random(length: 5)
        let address = "\(String(Int.random(in: 0..<Int.max)))@gmail.com"
        return Address(name: name, address: address)!
    }
    
    static func testCreatePostMessage(author: Address) -> CreatePostMessage {
        let postMessageID = UIDWithMailbox(UID: UInt64.random(in: 0..<UInt64.max), mailbox: Mailbox(name: .friendlyMail, UIDValidity: 1))
        let postMessageHeader = MessageHeader(sender: author, from: author, to: [author], replyTo: [author], subject: "Fm", date: Date(), extraHeaders: [:], messageID: "")
       // let postMessageHeader = MessageHeader(sender: author, from: author, to: [author], replyTo: [author], subject: "Fm", date: Date())
        let postMessageBody = "Hi this is a test post about \(String.random(length: 5))."
        let postMessage = CreatePostMessage(uidWithMailbox: postMessageID, header: postMessageHeader, htmlBody: nil, plainTextBody: postMessageBody)
        return postMessage
    }
    
    static func loadEmail(withPath path: String, uid: UInt64, settings: Settings) -> BaseMessage? {
        let fileURL = URL(fileURLWithPath: path)
        let emailString = try! String(contentsOf: fileURL, encoding: .ascii)
        
        let data = emailString.data(using: .ascii)
        let parser = MCOMessageParser(data: data)!
        
        let mailbox = Mailbox(name: .friendlyMail, UIDValidity: 0)
        let parserHeader = parser.header!
        let header = MessageHeader(header: parserHeader, mailbox: mailbox)!
                
        let messageID = UIDWithMailbox(UID: uid, mailbox: mailbox)
        
        // Create message from email loaded from file
        
        if let fm = MessageFactory.createMessage(settings: settings, uidWithMailbox: messageID, header: header, htmlBody: parser.htmlBodyRendering(), plainTextBody: parser.plainTextBodyRendering()) {
            return fm
        } else {
            return Message(uidWithMailbox: messageID, header: header, htmlBody: parser.htmlBodyRendering(), plainTextBody: parser.plainTextBodyRendering())
        }
    }
    
     /*
    static func testPostNotificationMessage(postAuthor: Address, postMessageID: MessageID, follower: Address) -> PostNotificationMessage {
        let notificationMessageID = MessageID(UID: 2, mailbox: Mailbox(name: .sent, UIDValidity: 1))
        let notificationMessageHeader = MessageHeader(sender: postAuthor, from: postAuthor, to: [follower], replyTo: [postAuthor], subject: "New Post From Phil", date: Date())
        
        
        
        let notificationMessageBody = "Phil posted something."
        let notificationMessage = PostNotificationMessage(messageID: notificationMessageID, header: notificationMessageHeader, htmlBody: nil, plainTextBody: notificationMessageBody, postMessageID: postMessageID)
        
        return notificationMessage
    }
    */
}
