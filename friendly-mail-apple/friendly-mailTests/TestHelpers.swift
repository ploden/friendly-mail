//
//  TestHelpers.swift
//  friendly-mailTests
//
//  Created by Philip Loden on 9/8/21.
//

import XCTest
import Foundation
@testable import friendly_mail_ios
@testable import friendly_mail_core
//import MailCore

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
    
    static func testCreatePostMessage(author: Address) -> CreatePostingMessage {
        let postMessageID = UIDWithMailbox(UID: UInt64.random(in: 0..<UInt64.max), mailbox: Mailbox(name: .friendlyMail, UIDValidity: 1))
        let postMessageHeader = MessageHeader(sender: author, from: author, to: [author], replyTo: [author], subject: "Fm", date: Date(), extraHeaders: [:], messageID: "")
       // let postMessageHeader = MessageHeader(sender: author, from: author, to: [author], replyTo: [author], subject: "Fm", date: Date())
        let postMessageBody = "Hi this is a test post about \(String.random(length: 5))."
        let postMessage = CreatePostingMessage(uidWithMailbox: postMessageID, header: postMessageHeader!, htmlBody: nil, plainTextBody: postMessageBody, attachments: nil)
        return postMessage
    }
    
    static func processMailAndSend(config: AppConfig,
                                   sender: MessageSender,
                                   receiver: MessageReceiver,
                                   testCase: XCTestCase,
                                   provider: inout MailProvider)
    {
        var messages = provider.messages
        TestHelpers.processMailAndSend(config: config, sender: sender, receiver: receiver, testCase: testCase, messages: &messages)
        provider = provider.new(mergingMessageStores: messages, postNotification: false)
    }
    
    static func processMailAndSend(config: AppConfig,
                                   sender: MessageSender,
                                   receiver: MessageReceiver,
                                   testCase: XCTestCase,
                                   messages: inout MessageStore)
    {
        let results = MailController.processMail(config: config, sender: sender, receiver: receiver, messages: messages)
        
        results.drafts.forEach { draft in
            let group = DispatchGroup()
            group.enter()
            
            var anID: MessageID? = nil
            
            // avoid deadlocks by not using .main queue here
            DispatchQueue.global(qos: .background).async {
                sender.sendDraft(draft: draft) { error, messageID in
                    anID = messageID
                    group.leave()
                }
            }
            
            // wait ...
            group.wait()
            
            if
                let messageID = anID,
                let testSender = sender as? TestSenderReceiver,
                let sentMessage = testSender.sentMessages.getMessage(for: messageID)
            {
                messages = messages.addingMessage(message: sentMessage, messageID: messageID)
            }
        }
    }
    
    static func loadEmail(account: FriendlyMailAccount?, withPath path: String, uid: inout UInt64, messages: inout MessageStore) -> BaseMessage? {
        let message = TestHelpers.loadEmail(account: account, withPath: path, uid: uid)
        uid += 1
        messages = messages.addingMessage(message: message!, messageID: message!.header.messageID)
        return message
    }
    
    static func loadEmail(account: FriendlyMailAccount?, withPath path: String, uid: inout UInt64, provider: inout MailProvider) -> BaseMessage? {
        var inoutMessages: MessageStore! = provider.messages
        let message = TestHelpers.loadEmail(account: inoutMessages.account, withPath: path, uid: &uid, messages: &inoutMessages)
        provider = provider.new(mergingMessageStores: inoutMessages, postNotification: false)
        inoutMessages = nil
        return message
    }
    
    static func loadEmail(account: FriendlyMailAccount?, withPath path: String, uid: UInt64) -> BaseMessage? {
        let fileURL = URL(fileURLWithPath: path)
        let emailString = try! String(contentsOf: fileURL, encoding: .ascii)
        
        let data = emailString.data(using: .ascii)
        let parser = MCOMessageParser(data: data)!
        
        let mailbox = Mailbox(name: .friendlyMail, UIDValidity: 0)
        let parserHeader = parser.header!
        let header = MessageHeader(header: parserHeader, mailbox: mailbox)!
                
        let messageID = UIDWithMailbox(UID: uid, mailbox: mailbox)
        
        // Create message from email loaded from file
        
        let htmlBody = parser.htmlBodyRendering()
        
        if
            let fm = MessageFactory.createMessage(account: account,
                                                  uidWithMailbox: messageID,
                                                  header: header,
                                                  htmlBody: htmlBody,
                                                  friendlyMailData: MailProvider.friendlyMailData(for: htmlBody),
                                                  plainTextBody: parser.plainTextBodyRendering(),
                                                  attachments: MailProvider.attachments(forAny: parser),
                                                  logger: nil)
        {
            return fm
        } else {
            return Message(uidWithMailbox: messageID, header: header, htmlBody: parser.htmlBodyRendering(), plainTextBody: parser.plainTextBodyRendering(), attachments: nil)
        }
    }
    
    static func writeToTmpDir(string: String, filename: String) -> String? {
        if let data = string.data(using: .utf8) {
            return TestHelpers.writeToTmpDir(data: data, filename: filename)
        }
        return nil
    }

    static func writeToTmpDir(data: Data, filename: String) -> String? {
        let dir = NSTemporaryDirectory()
        let filepath = "\(dir)/\(filename)"
        FileManager.default.createFile(atPath: filepath, contents: data)
        return filepath
    }
    
    static func printDiff(first: String, second: String) {
        let firstLines = first.split(whereSeparator: \.isNewline)
        let secondLines = second.split(whereSeparator: \.isNewline)
        
        let num = min(firstLines.count, secondLines.count)
        
        for i in 0..<num {
            let firstLine = firstLines[i]
            let secondLine = secondLines[i]
            
            if firstLine != secondLine {
                print("Lines \(i) do not match:")
                print(firstLine)
                print(secondLine)
                return
            }
        }
        
        if firstLines.count != secondLines.count {
            print("printDiff: number of lines does not match")
            print("first last line: \(firstLines.last!)")
            print("second last line: \(secondLines.last!)")
        } else {
            print("printDiff: strings match")
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