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
    
    func testCreatePostMessage() async throws {
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let subject = "Fm"
        let body = "This is a test post."
        let messageID = UIDWithMailbox(UID: UInt64.random(in: 1..<UInt64.max), mailbox: Mailbox(name: MailboxName.friendlyMail, UIDValidity: 1))
        let header = MessageHeader(sender: user, from: user, to: [user], replyTo: [user], subject: subject, date: Date(), extraHeaders: [:], messageID: "")

        var uid: UInt64 = 1
        let theme = await (UIApplication.shared.delegate as! AppDelegate).appConfig.defaultTheme
        let settings = AppleSettings(user: user, selectedTheme: theme)
                        
        let senderReceiver = TestSenderReceiver()
        senderReceiver.user = user
        senderReceiver.settings = settings
        
        let config = await (UIApplication.shared.delegate as! AppDelegate).appConfig
        
        var messages = MessageStore()
        
        await MessageReceiverTests.loadCreateAccountEmailAndSendResponse(config: config,
                                                                   sender: senderReceiver,
                                                                   receiver: senderReceiver,
                                                                   testCase: self,
                                                                   uid: &uid,
                                                                   messages: &messages)
                
        let message = MessageFactory.createMessage(account: messages.account,
                                                   uidWithMailbox: messageID,
                                                   header: header!,
                                                   htmlBody: nil,
                                                   friendlyMailData: nil,
                                                   plainTextBody: body,
                                                   attachments: nil,
                                                   logger: nil) as? CreatePostingMessage ?? nil
        
        XCTAssertNotNil(message, "Message is not nil.")
        XCTAssertNotNil(message?.post)
        XCTAssert(message?.plainTextBody == body, "post body is not correct")
    }
    
    func testCreateAccountSucceededCommandResultMessage() async throws {
        let (_, senderReceiver, _) = await TestHelpers.defaultSetup(testCase: self)
        
        let sentMessage = senderReceiver.sentMessages.allMessages.last!

        XCTAssertNotNil(sentMessage)
        XCTAssert(sentMessage is CreateAccountSucceededCommandResultMessage)
        XCTAssert((sentMessage as! CreateAccountSucceededCommandResultMessage).commandResult is CreateAccountSucceededCommandResult)
        
        let result = MessageFactory.extractCreateCommandSucceededCommandResult(htmlBody: sentMessage.htmlBody, friendlyMailHeader: sentMessage.header.friendlyMailHeader, friendlyMailData: MailProvider.friendlyMailData(for: sentMessage.htmlBody))

        XCTAssertNotNil(result)
    }
    
    /*
    func testCreateAddFollowersMessage() throws {
        // Load email from file
        let path = Bundle(for: type(of: self )).path(forResource: "create_add_followers", ofType: "txt")!

        let uid: UInt64 = 1
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let theme = (UIApplication.shared.delegate as! AppDelegate).appConfig.defaultTheme
        let correctSettings = TestSettings(user: user, password: "", selectedTheme: theme)
        let correctMessage = TestHelpers.loadEmail(accountAddress: user, withPath: path, uid: uid)
        
        XCTAssert(correctMessage is CreateAddFollowersMessage)
        
        let createAddFollowersMessage = correctMessage as! CreateAddFollowersMessage
        XCTAssert(createAddFollowersMessage.subscriptions.count == 1)
    }
     */
    
    /*
    func testCreateInvitesMessage() throws {
        // Load email from file
        let path = Bundle(for: type(of: self )).path(forResource: "create_invite", ofType: "txt")!

        let uid: UInt64 = 1
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let theme = (UIApplication.shared.delegate as! AppDelegate).appConfig.defaultTheme
        let correctSettings = TestSettings(user: user, password: "", selectedTheme: theme)
        let correctMessage = TestHelpers.loadEmail(accountAddress: user, withPath: path, uid: uid)
        
        XCTAssert(correctMessage is CreateInvitesMessage)
        
        let createInvitesMessage = correctMessage as! CreateInvitesMessage
        XCTAssert(createInvitesMessage.invites.count == 1)
    }
     */
    
    /*
    func testNotificationsMessage() throws {
        // Load email from file
        let path = Bundle(for: type(of: self )).path(forResource: "notifications", ofType: "txt")!

        let uid: UInt64 = 1
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let theme = (UIApplication.shared.delegate as! AppDelegate).appConfig.defaultTheme
        let correctSettings = TestSettings(user: user, password: "", selectedTheme: theme)
        let correctMessage = TestHelpers.loadEmail(accountAddress: user, withPath: path, uid: uid)
        
        XCTAssert(correctMessage is NotificationsMessage)
        
        if let correctMessage = correctMessage as? NotificationsMessage {
            XCTAssert(correctMessage.notifications.count == 1)
        }
    }
     */
    
    func testSetProfilePicMessage() async throws {
        let config = await (UIApplication.shared.delegate as! AppDelegate).appConfig
        var (provider, _, uid) = await TestHelpers.defaultSetup(testCase: self)
        
        let path = Bundle(for: type(of: self )).path(forResource: "set_profile_pic", ofType: "txt")!
        let correctMessage = TestHelpers.loadEmail(account: provider.messages.account, withPath: path, uid: &uid, provider: &provider)

        XCTAssert(correctMessage is CreateCommandsMessage)
        
        if let commandMessage = correctMessage as? CreateCommandsMessage {
            XCTAssert(commandMessage.commands.count == 1)
            
            let command = commandMessage.commands.first!
            XCTAssert(command.commandType == .setProfilePic)
            
            let photoAttachmentOrNil = commandMessage.attachments!.first { $0.mimeType == "image/jpeg" }
            XCTAssertNotNil(photoAttachmentOrNil)
            
            /*
            let photoAttachment = photoAttachmentOrNil!
            let profilePicPath = Bundle(for: type(of: self )).path(forResource: "phil_profile_pic_attachment", ofType: "jpeg")!
            let profilePicURL = URL(fileURLWithPath: profilePicPath)
            let profilePicData = try! Data(contentsOf: profilePicURL)

            let path = TestHelpers.writeToTmpDir(data: photoAttachment.data, filename: "profile_pic_attach.jpeg")
            print(path!)
            TestHelpers.writeToTmpDir(data: profilePicData, filename: "profile_pic_file.jpeg")

            XCTAssert(photoAttachment.data == profilePicData)
             */
        }
    }
    
    func testCreateAccountMessage() async throws {
        let path = Bundle(for: type(of: self )).path(forResource: "create_command_create_account", ofType: "txt")!

        let (provider, _, uid) = await TestHelpers.defaultSetup(testCase: self)
        let correctMessage = TestHelpers.loadEmail(account: provider.messages.account, withPath: path, uid: uid)
        
        XCTAssert(correctMessage is CreateCommandsMessage)
        let commandMessage = correctMessage as! CreateCommandsMessage
        XCTAssert(commandMessage.commands.first!.commandType == .createAccount)
    }
    
    func testCommandNotFoundMessage() async throws {
        let path = Bundle(for: type(of: self )).path(forResource: "create_command_not_found", ofType: "txt")!

        let (provider, _, uid) = await TestHelpers.defaultSetup(testCase: self)
        let correctMessage = TestHelpers.loadEmail(account: provider.messages.account, withPath: path, uid: uid)
        
        XCTAssert(correctMessage is CreateCommandsMessage)
        let commandMessage = correctMessage as! CreateCommandsMessage
        XCTAssert(commandMessage.commands.first!.commandType == .unknown)
    }

    func testExtractMessageID() throws {
        let mID = "4EC2D8F3-DD53-43CD-B38C-1AFDD5149C7C@gmail.com"
        let label = "Comment"
        let commentString = "Fm \(label):\(mID)"
        let extracted = MessageFactory.extractMessageID(withLabel: label, from: commentString)
        XCTAssert(extracted == mID)
    }
    
    func testExtractCommandsSetProfilePic() throws {
        let plainTextBody = "Fm: set profile pic"
        let messageID = ""
        let extracted = MessageFactory.extractCommands(messageID: messageID, htmlBody: nil, plainTextBody: plainTextBody)
        XCTAssert(extracted!.first!.commandType == .setProfilePic)
    }

    func testExtractCommandsAddSingleFollower() throws {
        let plainTextBody = "Fm: add follower ploden.postcards@gmail.com"
        let messageID = ""
        let extracted = MessageFactory.extractCommands(messageID: messageID, htmlBody: nil, plainTextBody: plainTextBody)
        XCTAssert(extracted!.first!.commandType == .addFollowers)
    }

    func testExtractCommandsAddMultipleFollowers() throws {
        let plainTextBody = "Fm: add followers ploden.postcards@gmail.com second@second.com"
        let messageID = ""
        let extracted = MessageFactory.extractCommands(messageID: messageID, htmlBody: nil, plainTextBody: plainTextBody)
        XCTAssert(extracted!.first!.commandType == .addFollowers)
    }
    
    func testExtractFollowersToAdd() throws {
        let single = "add follower ploden.postcards@gmail.com"
        let singleFollower = MessageFactory.extractFollowersToAdd(plainTextBody: single)
        XCTAssert(singleFollower.count == 1)
        let multiple = "add followers ploden.postcards@gmail.com second@second.com"
        let multipleFollowers = MessageFactory.extractFollowersToAdd(plainTextBody: multiple)
        XCTAssert(multipleFollowers.count == 2)
    }
    
    /*
    func testExtractCreateCommandSucceededCommandResult() async throws {
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let subject = "Fm"

        var uid: UInt64 = 1
        let theme = await (UIApplication.shared.delegate as! AppDelegate).appConfig.defaultTheme
        let settings = AppleSettings(user: user, selectedTheme: theme)
                        
        let senderReceiver = TestSenderReceiver()
        senderReceiver.user = user
        senderReceiver.settings = settings
        
        let config = await (UIApplication.shared.delegate as! AppDelegate).appConfig
        
        var messages = MessageStore()
        
        await MessageReceiverTests.loadCreateAccountEmailAndSendResponse(config: config,
                                                                   sender: senderReceiver,
                                                                   receiver: senderReceiver,
                                                                   testCase: self,
                                                                   uid: &uid,
                                                                   messages: &messages)
        
        var provider = MailProvider(settings: settings, messages: messages)
        let path = Bundle(for: type(of: self )).path(forResource: "create_account_succeeded_command_result", ofType: "txt")!
        let message = TestHelpers.loadEmail(account: messages.account, withPath: path, uid: &uid, provider: &provider)
        
        let result = MessageFactory.extractCreateCommandSucceededCommandResult(htmlBody: message!.htmlBody, friendlyMailHeader: message!.header.friendlyMailHeader, friendlyMailData: MailProvider.friendlyMailData(for: message!.htmlBody))
        
        XCTAssertNotNil(result)
    }
     */
    
}
