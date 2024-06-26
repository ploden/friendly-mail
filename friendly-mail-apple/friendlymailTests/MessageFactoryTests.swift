//
//  MessageFactoryTests.swift
//  friendlymailTests
//
//  Created by Philip Loden on 9/1/21.
//

import XCTest
@testable import friendlymail_ios
@testable import friendlymail_core

class MessageFactoryTests: XCTestCase {
    
    func testCreatePostMessage() async throws {
        let (provider, _, uid) = await TestHelpers.defaultSetup(testCase: self)

        let subject = "Fm"
        let body = "This is a test post."
        let messageID = UIDWithMailbox(UID: UInt64.random(in: 1..<UInt64.max), mailbox: Mailbox(name: MailboxName.friendlyMail, UIDValidity: 1))

        let user = provider.messages.hostUser!.email
        
        let header = MessageHeader(host: user, from: user, to: [user], replyTo: [user], subject: subject, date: Date(), extraHeaders: [:], messageID: "")
        
        let message = MessageFactory.createMessage(account: provider.messages.hostUser,
                                                   uidWithMailbox: messageID,
                                                   header: header!,
                                                   htmlBody: nil,
                                                   friendlyMailData: nil,
                                                   plainTextBody: body,
                                                   attachments: nil,
                                                   logger: nil)
        
        XCTAssertNotNil(message, "Message is nil.")
        
        XCTAssertNotNil(message as? CreatePostingMessage, "createPostingMessage is nil.")

        if let createPostingMessage = message as? CreatePostingMessage {
            XCTAssertNotNil(createPostingMessage.posting)
            XCTAssert(createPostingMessage.plainTextBody == body, "post body is not correct")
        }
    }
    
    func testCreateAccountSucceededCommandResultMessage() async throws {
        let (provider, senderReceiver, _) = await TestHelpers.defaultSetup(testCase: self)
        
        let resultOrNil = provider.messages.commandResults(ofType: CreateAccountSucceededCommandResult.self).first
        
        XCTAssertNotNil(resultOrNil)
        
        if let result = resultOrNil {
            let resultsMessage = provider.messages.getCommandResultsMessage(for: result)!
            
            let extractedResult = MessageFactory.extractCreateCommandSucceededCommandResult(htmlBody: resultsMessage.htmlBody, friendlyMailHeader: resultsMessage.header.friendlyMailHeader, friendlyMailData: MailProvider.friendlyMailData(for: resultsMessage.htmlBody))
            
            XCTAssertNotNil(extractedResult)
            XCTAssert(extractedResult == result)
        }
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
        let correctMessage = TestHelpers.loadEmail(account: provider.messages.hostUser, withPath: path, uid: &uid, provider: &provider)

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
        
        let correctMessage = TestHelpers.loadEmail(host: provider.address, account: provider.messages.hostUser, withPath: path, uid: uid)
        
        XCTAssert(correctMessage is CreateCommandsMessage)
        
        if let commandMessage = correctMessage as? CreateCommandsMessage {
            XCTAssert(commandMessage.commands.first!.commandType == .createAccount)
        }
    }
    
    func testCreateCommentMessage() async throws {
        let path = Bundle(for: type(of: self )).path(forResource: "create_comment", ofType: "txt")!

        let (provider, _, uid) = await TestHelpers.defaultSetup(testCase: self)
        
        let correctMessage = TestHelpers.loadEmail(host: provider.address, account: provider.messages.hostUser, withPath: path, uid: uid)
        
        XCTAssert(correctMessage is CreateCommentMessage)
        "Friday 11am green trees"
        if let commentMessage = correctMessage as? CreateCommentMessage {
            XCTAssert(commentMessage.posting.articleBody == "Hello back.")
        }
    }
    
    func testCommandNotFoundMessage() async throws {
        let path = Bundle(for: type(of: self )).path(forResource: "create_command_not_found", ofType: "txt")!

        let (provider, _, uid) = await TestHelpers.defaultSetup(testCase: self)
        let correctMessage = TestHelpers.loadEmail(host: provider.address, account: provider.messages.hostUser, withPath: path, uid: uid)
        
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
    
    func testExtractCommandsCreateAccount() throws {
        let plainTextBody = "\(CreateCommandsMessage.commandPrefix)useradd"
        let messageID = ""
        let user = EmailAddress(displayName: "Phil Loden", address: "ploden@gmail.com")!
        let extracted = MessageFactory.extractCommands(host: user, user: user, messageID: messageID, htmlBody: nil, plainTextBody: plainTextBody)
        XCTAssert(extracted!.first!.commandType == .createAccount)
    }
    
    func testExtractCommandsCreateAccountWithTrailingSpace() throws {
        let plainTextBody = "\(CreateCommandsMessage.commandPrefix)useradd "
        let messageID = ""
        let user = EmailAddress(displayName: "Phil Loden", address: "ploden@gmail.com")!
        let extracted = MessageFactory.extractCommands(host: user, user: user, messageID: messageID, htmlBody: nil, plainTextBody: plainTextBody)
        XCTAssert(extracted!.first!.commandType == .createAccount)
    }
    
    func testExtractCommandsCreateAccountWithSig() throws {
        let plainTextBody = "\(CreateCommandsMessage.commandPrefix)useradd\nPhil"
        let messageID = ""
        let user = EmailAddress(displayName: "Phil Loden", address: "ploden@gmail.com")!
        let extracted = MessageFactory.extractCommands(host: user, user: user, messageID: messageID, htmlBody: nil, plainTextBody: plainTextBody)
        XCTAssert(extracted!.first!.commandType == .createAccount)
    }
    
    func testExtractCommandsCreateAccountWithAnotherSig() throws {
        let plainTextBody = "\(CreateCommandsMessage.commandPrefix)useradd\n\nPhil"
        let messageID = ""
        let user = EmailAddress(displayName: "Phil Loden", address: "ploden@gmail.com")!
        let extracted = MessageFactory.extractCommands(host: user, user: user, messageID: messageID, htmlBody: nil, plainTextBody: plainTextBody)
        XCTAssert(extracted!.first!.commandType == .createAccount)
    }
    
    func testExtractCommandsSetProfilePic() throws {
        let plainTextBody = "\(CreateCommandsMessage.commandPrefix)usermod"
        let messageID = ""
        let user = EmailAddress(displayName: "Phil Loden", address: "ploden@gmail.com")!
        let extracted = MessageFactory.extractCommands(host: user, user: user, messageID: messageID, htmlBody: nil, plainTextBody: plainTextBody)
        XCTAssert(extracted!.first!.commandType == .setProfilePic)
    }

    func testExtractCommandsAddSingleFollower() throws {
        let plainTextBody = "\(CreateCommandsMessage.commandPrefix)follow add ploden.postcards@gmail.com"
        let messageID = ""
        let user = EmailAddress(displayName: "Phil Loden", address: "ploden@gmail.com")!
        let extracted = MessageFactory.extractCommands(host: user, user: user, messageID: messageID, htmlBody: nil, plainTextBody: plainTextBody)
        XCTAssert(extracted!.first!.commandType == .follow)
    }

    func testExtractCommandsAddMultipleFollowers() throws {
        let plainTextBody = "\(CreateCommandsMessage.commandPrefix)follow add ploden.postcards@gmail.com second@second.com"
        let messageID = ""
        let user = EmailAddress(displayName: "Phil Loden", address: "ploden@gmail.com")!
        let extracted = MessageFactory.extractCommands(host: user, user: user, messageID: messageID, htmlBody: nil, plainTextBody: plainTextBody)
        XCTAssert(extracted!.first!.commandType == .follow)
    }
    
    func testExtractFollowersToAdd() throws {
        let single = "follow add ploden.postcards@gmail.com"
        let user = EmailAddress(displayName: "Phil Loden", address: "ploden@gmail.com")!
        let singleFollower = CommandController.extractFollowersToAdd(plainTextBody: single, host: user)
        XCTAssert(singleFollower.count == 1)
        let multiple = "follow add ploden.postcards@gmail.com second@second.com"
        let multipleFollowers = CommandController.extractFollowersToAdd(plainTextBody: multiple, host: user)
        XCTAssert(multipleFollowers.count == 2)
    }
    
    func testIsFMSubject() throws {
        XCTAssertFalse(MessageFactory.isFMSubject(subject: nil))
        XCTAssertFalse(MessageFactory.isFMSubject(subject: ""))
        XCTAssert(MessageFactory.isFMSubject(subject: "Fm"))
        XCTAssert(MessageFactory.isFMSubject(subject: "Fm "))
        XCTAssert(MessageFactory.isFMSubject(subject: "fm"))
        XCTAssert(MessageFactory.isFMSubject(subject: "friendlymail: "))
        XCTAssert(MessageFactory.isFMSubject(subject: "Friendlymail: "))
        XCTAssert(MessageFactory.isFMSubject(subject: "friendlymail: "))
        XCTAssertFalse(MessageFactory.isFMSubject(subject: "friendlymail "))
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
