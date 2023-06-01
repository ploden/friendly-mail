//
//  TestHelpers.swift
//  friendlymailTests
//
//  Created by Philip Loden on 9/8/21.
//

import XCTest
import Foundation
@testable import friendlymail_ios
@testable import friendlymail_core

extension String {
    static func random(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}

class TestHelpers {
    
    static func testAddress(isHost: Bool) -> EmailAddress {
        let name = String.random(length: 5)
        let address = "\(String(Int.random(in: 0..<Int.max)))@gmail.com"
        return EmailAddress(displayName: name, address: address)!
    }
    
    /*
    static func testCreatePostMessage(author: Address) -> CreatePostingMessage {
        let postMessageID = UIDWithMailbox(UID: UInt64.random(in: 0..<UInt64.max), mailbox: Mailbox(name: .friendlyMail, UIDValidity: 1))
        let postMessageHeader = MessageHeader(host: , from: author, to: [author], replyTo: [author], subject: "Fm", date: Date(), extraHeaders: [:], messageID: "")
       // let postMessageHeader = MessageHeader(sender: author, from: author, to: [author], replyTo: [author], subject: "Fm", date: Date())
        let postMessageBody = "Hi this is a test post about \(String.random(length: 5))."
        let postMessage = CreatePostingMessage(uidWithMailbox: postMessageID, header: postMessageHeader!, htmlBody: nil, plainTextBody: postMessageBody, attachments: nil)
        return postMessage
    }
     */
    
    static func processMailAndSend(config: AppConfig,
                                   sender: MessageSender,
                                   receiver: MessageReceiver,
                                   testCase: XCTestCase,
                                   provider: inout MailProvider) async
    {
        var messages = provider.messages
        await TestHelpers.processMailAndSend(config: config, sender: sender, receiver: receiver, testCase: testCase, messages: &messages)
        provider = provider.new(mergingMessageStore: messages, postNotification: false)
    }
    
    static func processMailAndSend(config: AppConfig,
                                   sender: MessageSender,
                                   receiver: MessageReceiver,
                                   testCase: XCTestCase,
                                   messages: inout MessageStore) async
    {
        let logger = await (UIApplication.shared.delegate as! AppDelegate).logger

        let results = await MailController.processMail(config: config, sender: sender, receiver: receiver, messages: messages, storageProvider: TestStorageProvider(), logger: logger)
        
        let sentMessageIDs = await withTaskGroup(of: MessageID.self, returning: [MessageID].self) { group in
            for draft in results.drafts {
                group.async {
                    return try! await sender.sendDraft(draft: draft)
                }
            }
            
            var result: [MessageID] = []
            for await individualResult in group {
                result.append(individualResult)
            }
            return result
        }
        
        sentMessageIDs.forEach {
            if
                let testSender = sender as? TestSenderReceiver,
                let sentMessage = testSender.sentMessages.getMessage(for: $0)
            {
                messages = messages.addingMessage(message: sentMessage, messageID: $0)
            }
        }
        
        /*
        var sentMessageIDs = [MessageID]()
        
        results.drafts.forEach { draft in
            let group = DispatchGroup()
            group.enter()
            
            var anID: MessageID? = nil
            
            // avoid deadlocks by not using .main queue here
            DispatchQueue.global(qos: .background).async {
                sender.sendDraft(draft: draft) { sendDraftResult in
                    //anID = messageID
                    if let messageID = try? sendDraftResult.get() {
                        sentMessageIDs.append(messageID)
                    }
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
         */
    }
    
    static func loadEmail(host: EmailAddress, account: FriendlyMailUser?, withPath path: String, uid: inout UInt64, messages: inout MessageStore) -> (any AnyBaseMessage)? {
        let message = TestHelpers.loadEmail(host: host, account: account, withPath: path, uid: uid)
        uid += 1
        messages = messages.addingMessage(message: message!, messageID: message!.header.messageID)
        return message
    }
    
    static func loadEmail(account: FriendlyMailUser?, withPath path: String, uid: inout UInt64, provider: inout MailProvider) -> (any AnyBaseMessage)? {
        var inoutMessages: MessageStore! = provider.messages
        let message = TestHelpers.loadEmail(host: provider.settings.user, account: inoutMessages.hostUser, withPath: path, uid: &uid, messages: &inoutMessages)
        provider = provider.new(mergingMessageStore: inoutMessages, postNotification: false)
        inoutMessages = nil
        return message
    }
    
    static func loadEmail(host: EmailAddress, account: FriendlyMailUser?, withPath path: String, uid: UInt64) -> (any AnyBaseMessage)? {
        let fileURL = URL(fileURLWithPath: path)
        let emailString = try! String(contentsOf: fileURL, encoding: .ascii)
        
        let data = emailString.data(using: .ascii)
        let parser = MCOMessageParser(data: data)!
        
        let mailbox = Mailbox(name: .friendlyMail, UIDValidity: 0)
        let parserHeader = parser.header!
        let header = MessageHeader(host: host, header: parserHeader, mailbox: mailbox)!
                
        let messageID = UIDWithMailbox(UID: uid, mailbox: mailbox)
        
        // Create message from email loaded from file
        
        let htmlBody = parser.htmlBodyRendering()
        
        if
            let fm = MessageFactory.createMessage(account: account,
                                                  uidWithMailbox: messageID,
                                                  header: header,
                                                  htmlBody: htmlBody,
                                                  friendlyMailData: MailProvider.friendlyMailData(for: htmlBody),
                                                  plainTextBody: parser.plainTextBodyRenderingAndStripWhitespace(false),
                                                  attachments: MailProvider.attachments(forAny: parser),
                                                  logger: nil)
        {
            return fm
        } else {
            return Message(uidWithMailbox: messageID, header: header, htmlBody: parser.htmlBodyRendering(), plainTextBody: parser.plainTextBodyRenderingAndStripWhitespace(false), attachments: nil)
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
    
    static func defaultSetup(testCase: XCTestCase) async -> (MailProvider, TestSenderReceiver, UInt64) {
        var uid: UInt64 = 1
        let user = EmailAddress(displayName: "Phil Loden", address: "ploden@gmail.com")!
        let theme = await (UIApplication.shared.delegate as! AppDelegate).appConfig.defaultTheme
        let settings = AppleSettings(user: user, selectedTheme: theme)
        
        let senderReceiver = TestSenderReceiver()
        senderReceiver.user = user
        senderReceiver.settings = settings
        
        var provider = MailProvider(settings: settings, messages: MessageStore())
        
        let config = await (UIApplication.shared.delegate as! AppDelegate).appConfig
        
        var inoutMessages: MessageStore! = provider.messages
        
        await MessageReceiverTests.loadCreateAccountEmailAndSendResponse(config: config,
                                                                         sender: senderReceiver,
                                                                         receiver: senderReceiver,
                                                                         testCase: testCase,
                                                                         uid: &uid,
                                                                         messages: &inoutMessages)
        
        provider = provider.new(mergingMessageStore: inoutMessages, postNotification: false)
        
        // do it twice for self add
        await MessageReceiverTests.loadCreateAccountEmailAndSendResponse(config: config,
                                                                         sender: senderReceiver,
                                                                         receiver: senderReceiver,
                                                                         testCase: testCase,
                                                                         uid: &uid,
                                                                         messages: &inoutMessages)
        
        provider = provider.new(mergingMessageStore: inoutMessages, postNotification: false)
        
        return (provider, senderReceiver, uid)
    }
    
    static func messageCountIsUnchanged(testCase: XCTestCase, senderReceiver: TestSenderReceiver, provider: inout MailProvider, config: AppConfig) async -> Bool {
        let sentCountBefore = provider.messages.allMessages.count
        let countBefore = provider.messages.allMessages.count
        let before = provider.messages.allMessages
        var inoutMessages = provider.messages
        let messageIDsBefore = Set(provider.messages.allMessages.compactMap { $0.header.messageID } )
        await TestHelpers.processMailAndSend(config: config, sender: senderReceiver, receiver: senderReceiver, testCase: testCase, messages: &inoutMessages)
        provider = provider.new(mergingMessageStore: inoutMessages, postNotification: false)
        let sentCountAfter = provider.messages.allMessages.count
        let countAfter = provider.messages.allMessages.count
        let after = provider.messages.allMessages
        let messageIDsAfter = Set(provider.messages.allMessages.compactMap { $0.header.messageID } )
        let diff = messageIDsAfter.subtracting(messageIDsBefore)
        if diff.count > 0 {
            let diffMessages = diff.compactMap { provider.messages.getMessage(for: $0) }
            print("Diff:\n")
            diffMessages.forEach { print($0.shortDescription) }
            print("Before:\n")
            before.forEach { print($0.shortDescription) }
            print("After:\n")
            after.forEach { print($0.shortDescription) }
        }
        return sentCountBefore == sentCountAfter && countBefore == countAfter
    }
    
    static func assertEqual(first: String, second: String, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(first, second, "\n****First:****\n\n\(first)\n\n****Second:****\n\n\(second)\n\n", file: file, line: line)

    }

}
