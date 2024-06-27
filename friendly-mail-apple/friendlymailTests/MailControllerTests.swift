//
//  MailControllerTests.swift
//  friendlymailTests
//
//  Created by Philip Loden on 9/2/21.
//

import XCTest
@testable import friendlymail_ios
@testable import friendlymail_core

class MailControllerTests: XCTestCase {

    func testHelp() async throws {
        let config = await (UIApplication.shared.delegate as! AppDelegate).appConfig
        var (provider, senderReceiver, uid) = await TestHelpers.defaultSetup(testCase: self)

        let path = Bundle(for: type(of: self )).path(forResource: "create_command_help", ofType: "txt")!
        let loadedEmail = TestHelpers.loadEmail(account: provider.messages.hostUser, withPath: path, uid: &uid, provider: &provider)
        
        XCTAssert(loadedEmail is CreateCommandsMessage)
        
        var inoutMessages: MessageStore! = provider.messages

        await TestHelpers.processMailAndSend(config: config, sender: senderReceiver, receiver: senderReceiver, testCase: self, messages: &inoutMessages)
        provider = provider.new(mergingMessageStore: inoutMessages, postNotification: false)
        inoutMessages = nil

        let expectedPlainTextBody =
            """
    $ help
    friendlymail: friendlymail, version ???
    These shell commands are defined internally.  Type `help' to see this list.
    Type `help name' to find out more about the function `name'.
    
    useradd
    usermod
    invite
    follow
    help
    
    \(Template.PlainText.signature.rawValue)
    
    """
        
        let result = provider.messages.commandResults(ofType: CommandResult.self).filter { $0.createCommandMessageID == loadedEmail?.header.messageID }.first!
        XCTAssert(result.exitCode == CommandExitCode.success)
        
        let resultMessage = provider.messages.getCommandResultsMessage(for: result)!
        XCTAssertEqual(resultMessage.plainTextBody!, expectedPlainTextBody)
        
        let isUnchanged = await TestHelpers.messageCountIsUnchanged(testCase: self, senderReceiver: senderReceiver, provider: &provider, config: config)
        XCTAssert(isUnchanged)
    }
    
    func testCreateAccount() async throws {
        var uid: UInt64 = 1
        let user = EmailAddress(displayName: "Phil Loden", address: "ploden@gmail.com")!
        let theme = await (UIApplication.shared.delegate as! AppDelegate).appConfig.defaultTheme
        let settings = AppleSettings(user: user, selectedTheme: theme)
        
        var messages = MessageStore()
        
        let _ = MessageReceiverTests.loadCreateAccountEmail(testCase: self, uid: &uid, messages: &messages, host: settings.user)
        
        let senderReceiver = TestSenderReceiver()
        senderReceiver.user = user
        senderReceiver.settings = settings
        
        var provider = MailProvider(settings: settings, messages: messages)
        let config = await (UIApplication.shared.delegate as! AppDelegate).appConfig
        await TestHelpers.processMailAndSend(config: config, sender: senderReceiver, receiver: senderReceiver, testCase: self, provider: &provider)

        XCTAssert(provider.messages.allMessages.count == 3)
                
        await TestHelpers.processMailAndSend(config: config, sender: senderReceiver, receiver: senderReceiver, testCase: self, provider: &provider)

        // one more because of reply to add follower command
        XCTAssert(provider.messages.allMessages.count == 4)

        let expectedPlainTextBody =
            """
    $ useradd
    friendlymail: account created for ploden@gmail.com
    
    \(Template.PlainText.signature.rawValue)
    
    """
        
        let commandResult = provider.messages.commandResults(ofType: CreateAccountSucceededCommandResult.self).first!
        let sentMessage = provider.messages.getCommandResultsMessage(for: commandResult)!
        
        XCTAssertEqual(sentMessage.plainTextBody!, expectedPlainTextBody)
        
        let isUnchanged = await TestHelpers.messageCountIsUnchanged(testCase: self, senderReceiver: senderReceiver, provider: &provider, config: config)
        XCTAssert(isUnchanged)
        
        let handledCommands = provider.messages.handledCommands(host: provider.messages.hostUser!.email)
        XCTAssert(handledCommands.count == 2) // 1 useradd and 1 follow
    }
    
    func testCreateAccountAndSendResponse() async throws {
        let config = await (UIApplication.shared.delegate as! AppDelegate).appConfig
        var (provider, senderReceiver, uid) = await TestHelpers.defaultSetup(testCase: self)
        var inoutMessages: MessageStore! = provider.messages
        
        await MessageReceiverTests.loadCreateAccountEmailAndSendResponse(config: config,
                                                                   sender: senderReceiver,
                                                                   receiver: senderReceiver,
                                                                   testCase: self,
                                                                   uid: &uid,
                                                                   messages: &inoutMessages)

        let account = inoutMessages.hostUser
        
        XCTAssertNotNil(account)
    }
    
    func testCreateAccountAndSendResponseAndSendSelfFollow() async throws {
        let config = await (UIApplication.shared.delegate as! AppDelegate).appConfig
        var (provider, senderReceiver, uid) = await TestHelpers.defaultSetup(testCase: self)
        var inoutMessages: MessageStore! = provider.messages
        
        await MessageReceiverTests.loadCreateAccountEmailAndSendResponse(config: config,
                                                                         sender: senderReceiver,
                                                                         receiver: senderReceiver,
                                                                         testCase: self,
                                                                         uid: &uid,
                                                                         messages: &inoutMessages)

        provider = provider.new(mergingMessageStore: inoutMessages, postNotification: false)
        inoutMessages = nil
        
        let account = provider.messages.hostUser
        XCTAssertNotNil(account)

        let messageOrNil = provider.messages.allMessages.first(where: { message in
            return (message as? CommandResultsMessage)?.commandResults.contains(where: { $0 is AddFollowersSucceededCommandResult } ) ?? false
        })
        XCTAssertNotNil(messageOrNil)
        
        let isUnchanged = await TestHelpers.messageCountIsUnchanged(testCase: self, senderReceiver: senderReceiver, provider: &provider, config: config)
        XCTAssert(isUnchanged)
        
        let isUnchangedAgain = await TestHelpers.messageCountIsUnchanged(testCase: self, senderReceiver: senderReceiver, provider: &provider, config: config)
        XCTAssert(isUnchangedAgain)
    }
    
    func testAccountAlreadyExists() async throws {
        let config = await (UIApplication.shared.delegate as! AppDelegate).appConfig
        var (provider, senderReceiver, uid) = await TestHelpers.defaultSetup(testCase: self)
        
        var inoutMessages: MessageStore! = provider.messages
        let account = provider.messages.hostUser
        
        XCTAssertNotNil(account)
        
        let path = Bundle(for: type(of: self )).path(forResource: "create_command_create_account_2", ofType: "txt")!
        let loadedEmail = TestHelpers.loadEmail(account: account, withPath: path, uid: &uid, provider: &provider)
        inoutMessages = provider.messages
        senderReceiver.account = account
        await TestHelpers.processMailAndSend(config: config, sender: senderReceiver, receiver: senderReceiver, testCase: self, messages: &inoutMessages)
        provider = provider.new(mergingMessageStore: inoutMessages, postNotification: false)
        inoutMessages = nil
                
        XCTAssertNotNil(account)
        
        let result = provider.messages.commandResults(ofType: CommandResult.self).filter { $0.createCommandMessageID == loadedEmail?.header.messageID }.first!
        XCTAssert(result.exitCode == CommandExitCode.fail)
        
        let expectedPlainTextBody =
            """
    $ useradd
    friendlymail: account already exists for ploden@gmail.com
    
    \(Template.PlainText.signature.rawValue)
    
    """
        
        let resultMessage = provider.messages.getCommandResultsMessage(for: result)!
        XCTAssert(resultMessage.plainTextBody! == expectedPlainTextBody)
        
        let isUnchanged = await TestHelpers.messageCountIsUnchanged(testCase: self, senderReceiver: senderReceiver, provider: &provider, config: config)
        XCTAssert(isUnchanged)
    }
    
    func testCreateAccountPermissionDenied() async throws {
        let config = await (UIApplication.shared.delegate as! AppDelegate).appConfig
        var (provider, senderReceiver, uid) = await TestHelpers.defaultSetup(testCase: self)

        let path = Bundle(for: type(of: self )).path(forResource: "create_command_permission_denied", ofType: "txt")!
        let createEmail = TestHelpers.loadEmail(account: provider.messages.hostUser, withPath: path, uid: &uid, provider: &provider)
        
        var inoutMessages: MessageStore! = provider.messages

        await TestHelpers.processMailAndSend(config: config, sender: senderReceiver, receiver: senderReceiver, testCase: self, messages: &inoutMessages)
        provider = provider.new(mergingMessageStore: inoutMessages, postNotification: false)
        inoutMessages = nil

        let resultsForUser = provider.messages.commandResults(ofType: CommandResult.self, user: createEmail!.header.fromAddress)
        XCTAssert(resultsForUser.last!.exitCode == CommandExitCode.fail)
        
        let expectedPlainTextBody =
            """
    $ useradd
    friendlymail: permission denied
    
    \(Template.PlainText.signature.rawValue)
    
    """
        
        let resultMessage = provider.messages.getCommandResultsMessage(for: resultsForUser.last!)!
        XCTAssert(resultMessage.plainTextBody! == expectedPlainTextBody)
        
        let isUnchanged = await TestHelpers.messageCountIsUnchanged(testCase: self, senderReceiver: senderReceiver, provider: &provider, config: config)
        XCTAssert(isUnchanged)
    }
    
    func testSetProfilePic() async throws {
        let config = await (UIApplication.shared.delegate as! AppDelegate).appConfig
        var (provider, senderReceiver, uid) = await TestHelpers.defaultSetup(testCase: self)

        let path = Bundle(for: type(of: self )).path(forResource: "set_profile_pic", ofType: "txt")!
        let _ = TestHelpers.loadEmail(account: provider.messages.hostUser, withPath: path, uid: &uid, provider: &provider)
        
        var inoutMessages: MessageStore! = provider.messages

        await TestHelpers.processMailAndSend(config: config, sender: senderReceiver, receiver: senderReceiver, testCase: self, messages: &inoutMessages)
        provider = provider.new(mergingMessageStore: inoutMessages, postNotification: false)
        inoutMessages = nil

        let commandResult = provider.messages.commandResults(ofType: SetProfilePicSucceededCommandResult.self).last
        XCTAssert(commandResult!.exitCode == .success)
        
        let expectedPlainTextBody =
            """
    $ usermod
    friendlymail: successfully updated profile pic for \(provider.messages.hostUser!.email.address)
    
    \(Template.PlainText.signature.rawValue)
    
    """
       
        XCTAssertNotNil(commandResult!.profilePicURL)
        let commandResultMessage = provider.messages.getCommandResultsMessage(for: commandResult!)
        XCTAssert(commandResultMessage!.plainTextBody! == expectedPlainTextBody)
        
        let accountProfilePicURL = provider.messages.hostUser!.getProfilePicURL(messageStore: provider.messages)!
        XCTAssert(accountProfilePicURL == commandResult!.profilePicURL)
        
        let isUnchanged = await TestHelpers.messageCountIsUnchanged(testCase: self, senderReceiver: senderReceiver, provider: &provider, config: config)
        XCTAssert(isUnchanged)
    }
    
    /*
     A create follow add email exists. Was a corresponding CreateAddFollowersMessage object created?
     */
    func testAddFollowers() async throws {
        let config = await (UIApplication.shared.delegate as! AppDelegate).appConfig
        var (provider, senderReceiver, uid) = await TestHelpers.defaultSetup(testCase: self)

        let path = Bundle(for: type(of: self )).path(forResource: "create_add_followers", ofType: "txt")!
        let loadedEmail = TestHelpers.loadEmail(account: provider.messages.hostUser, withPath: path, uid: &uid, provider: &provider)
        
        XCTAssert(loadedEmail is CreateCommandsMessage)
        
        var inoutMessages: MessageStore! = provider.messages

        await TestHelpers.processMailAndSend(config: config, sender: senderReceiver, receiver: senderReceiver, testCase: self, messages: &inoutMessages)
        provider = provider.new(mergingMessageStore: inoutMessages, postNotification: false)
        inoutMessages = nil

        let expectedPlainTextBody =
            """
    $ follow add ploden.postcards@gmail.com
    friendlymail: added follower ploden.postcards@gmail.com
    
    \(Template.PlainText.signature.rawValue)
    
    """
       
        let addFollowersSucceededCommandResults = provider.messages.commandResults(ofType: AddFollowersSucceededCommandResult.self, user: senderReceiver.account?.email)
        //XCTAssert(addFollowersSucceededCommandResults.count == 2)
        let addFollowersSucceededCommandResult = addFollowersSucceededCommandResults.first(where: { $0.createCommandMessageID == loadedEmail!.header.messageID })!
        XCTAssertNotNil(addFollowersSucceededCommandResult.follows)
        
        let resultMessage = provider.messages.getCommandResultsMessage(for: addFollowersSucceededCommandResult)!
        XCTAssert(resultMessage.plainTextBody == expectedPlainTextBody, "\nExpected:\n\(expectedPlainTextBody)\nActual:\n\(resultMessage.plainTextBody!)")

        // Test for follows
        let follows = provider.messages.follows(followee: provider.messages.hostUser!.id)
        XCTAssert(follows.count == 2)
        
        let isUnchanged = await TestHelpers.messageCountIsUnchanged(testCase: self, senderReceiver: senderReceiver, provider: &provider, config: config)
        XCTAssert(isUnchanged)
    }
    
    ///  Scenario: an unsupported command is received, and replied to
    func testCreateCommandsAndCommandResult() async throws {
        let config = await (UIApplication.shared.delegate as! AppDelegate).appConfig
        var (provider, senderReceiver, uid) = await TestHelpers.defaultSetup(testCase: self)

        let path = Bundle(for: type(of: self )).path(forResource: "create_command_not_found", ofType: "txt")!
        let loadedEmail = TestHelpers.loadEmail(account: provider.messages.hostUser, withPath: path, uid: &uid, provider: &provider)
        
        XCTAssert(loadedEmail is CreateCommandsMessage)
        let _ = loadedEmail as! CreateCommandsMessage
        
        var inoutMessages: MessageStore! = provider.messages

        await TestHelpers.processMailAndSend(config: config, sender: senderReceiver, receiver: senderReceiver, testCase: self, messages: &inoutMessages)
        provider = provider.new(mergingMessageStore: inoutMessages, postNotification: false)
        inoutMessages = nil

        let resultOrNil = provider.messages.commandResults(ofType: CommandResult.self, user: senderReceiver.account?.email).filter { $0.createCommandMessageID == loadedEmail?.header.messageID}.first
        XCTAssertNotNil(resultOrNil)
        let result = resultOrNil!
        XCTAssert(result.commandType == .unknown)
        XCTAssert(result.exitCode == .fail)
        
        let expectedPlainTextBody =
        """
    $ aoeu
    friendlymail: aoeu: command not found

    \(Template.PlainText.signature.rawValue)

    """
   
        let resultMessage = provider.messages.getCommandResultsMessage(for: result)!

        XCTAssert(resultMessage.plainTextBody == expectedPlainTextBody)
        
        let isUnchanged = await TestHelpers.messageCountIsUnchanged(testCase: self, senderReceiver: senderReceiver, provider: &provider, config: config)
        XCTAssert(isUnchanged)
    }
    
    ///  Scenario: an unsupported command is received, and replied to only once
    func testCreateCommandsAndCommandResultNoDuplicates() async throws {
        let config = await (UIApplication.shared.delegate as! AppDelegate).appConfig
        var (provider, senderReceiver, uid) = await TestHelpers.defaultSetup(testCase: self)

        let path = Bundle(for: type(of: self )).path(forResource: "create_command_not_found", ofType: "txt")!
        let _ = TestHelpers.loadEmail(account: provider.messages.hostUser, withPath: path, uid: &uid, provider: &provider)
        
        var inoutMessages: MessageStore! = provider.messages

        await TestHelpers.processMailAndSend(config: config, sender: senderReceiver, receiver: senderReceiver, testCase: self, messages: &inoutMessages)
        provider = provider.new(mergingMessageStore: inoutMessages, postNotification: false)
        inoutMessages = nil
        
        inoutMessages = provider.messages
        await TestHelpers.processMailAndSend(config: config, sender: senderReceiver, receiver: senderReceiver, testCase: self, messages: &inoutMessages)
        provider = provider.new(mergingMessageStore: inoutMessages, postNotification: false)
        inoutMessages = nil
        
        let isUnchanged = await TestHelpers.messageCountIsUnchanged(testCase: self, senderReceiver: senderReceiver, provider: &provider, config: config)
        XCTAssert(isUnchanged)
    }
    
    /*
     Load a create follow email and a create post email. Is a notification message sent to follower?
     */
    func testAddFollowerAndCreatePostAndNotifyFollower() async throws {
        let config = await (UIApplication.shared.delegate as! AppDelegate).appConfig
        var (provider, senderReceiver, uid) = await TestHelpers.defaultSetup(testCase: self)
        
        var inoutMessages: MessageStore! = provider.messages
        let _ = MessageReceiverTests.loadCreateAddFollowersEmail(testCase: self, uid: &uid, provider: &provider)
        
        inoutMessages = provider.messages
        await TestHelpers.processMailAndSend(config: config, sender: senderReceiver, receiver: senderReceiver, testCase: self, messages: &inoutMessages)
        provider = provider.new(mergingMessageStore: inoutMessages, postNotification: false)
        inoutMessages = nil
        
        var follows = provider.messages.follows(followee: provider.messages.hostUser!.id)
        XCTAssert(follows.count == 2)
        
        let createPostEmail = MessageReceiverTests.loadCreatePostEmail(testCase: self, uid: &uid, provider: &provider)
                
        var postNotificationsCount = 0
        for follow in follows {
            let unsent = MailController.unsentNewPostNotifications(messages: provider.messages, for: follow)
            postNotificationsCount += unsent.count
        }
        XCTAssert(postNotificationsCount == 2)
        
        inoutMessages = provider.messages
        await TestHelpers.processMailAndSend(config: config, sender: senderReceiver, receiver: senderReceiver, testCase: self, messages: &inoutMessages)
        provider = provider.new(mergingMessageStore: inoutMessages, postNotification: false)
        inoutMessages = nil
        
        follows = provider.messages.follows(followee: provider.messages.hostUser!.id)
        XCTAssertNotNil(follows.count == 2)
        
        let notSelfFollow = follows.first(where: { $0.followerID != provider.messages.hostUser!.id } )!
        
        let notificationOrNil = provider.messages.notifications(follow: notSelfFollow).first
        XCTAssertNotNil(notificationOrNil)
        
        if let notification = notificationOrNil {
            let messageOrNil = provider.messages.getNotificationsMessage(for: notification)
            XCTAssertNotNil(messageOrNil)
            print(notification)
            if let message = messageOrNil {
                let subjectJSON = NotificationsMessageDraft.subjectBase64JSON(parentItemMessageID: createPostEmail!.header.messageID)

                let expectedPlainTextBody =
        """
Phil Loden posted:

"hello, world"

Like: mailto:ploden@gmail.com?subject=Fm%20\(Template.PlainText.likeSubject.rawValue)%20\(subjectJSON.like)&body=\(Template.PlainText.like.rawValue)
Comment: mailto:ploden@gmail.com?subject=Fm%20\(Template.PlainText.commentSubject.rawValue)%20\(subjectJSON.comment)

\(Template.PlainText.signature.rawValue)

"""
                
                XCTAssertEqual(message.plainTextBody!, expectedPlainTextBody)
            }
        }
        
        let isUnchanged = await TestHelpers.messageCountIsUnchanged(testCase: self, senderReceiver: senderReceiver, provider: &provider, config: config)
        XCTAssert(isUnchanged)
    }
    
    /*
     Load a create post email. Is a notification message sent to me?
     */
    func testAddFollowerAndCreatePostAndNotifySelf() async throws {
        let config = await (UIApplication.shared.delegate as! AppDelegate).appConfig
        var (provider, senderReceiver, uid) = await TestHelpers.defaultSetup(testCase: self)
        
        var inoutMessages: MessageStore! = provider.messages
        let _ = MessageReceiverTests.loadCreateAddFollowersEmail(testCase: self, uid: &uid, provider: &provider)
        
        inoutMessages = provider.messages
        await TestHelpers.processMailAndSend(config: config, sender: senderReceiver, receiver: senderReceiver, testCase: self, messages: &inoutMessages)
        provider = provider.new(mergingMessageStore: inoutMessages, postNotification: false)
        inoutMessages = nil
        
        var follows = provider.messages.follows(followee: provider.messages.hostUser!.id)
        XCTAssert(follows.count == 2)
        
        let createPostEmail = MessageReceiverTests.loadCreatePostEmail(testCase: self, uid: &uid, provider: &provider)
                
        var postNotificationsCount = 0
        for follow in follows {
            let unsent = MailController.unsentNewPostNotifications(messages: provider.messages, for: follow)
            postNotificationsCount += unsent.count
        }
        XCTAssert(postNotificationsCount == 2)
        
        inoutMessages = provider.messages
        await TestHelpers.processMailAndSend(config: config, sender: senderReceiver, receiver: senderReceiver, testCase: self, messages: &inoutMessages)
        provider = provider.new(mergingMessageStore: inoutMessages, postNotification: false)
        inoutMessages = nil
        
        follows = provider.messages.follows(followee: provider.messages.hostUser!.id)
        XCTAssertNotNil(follows.count == 2)
                        
        let selfFollow = follows.first(where: { $0.followerID == provider.messages.hostUser!.email.id } )!
        let notificationOrNil = provider.messages.notifications(ofType: Notification.self, follow: selfFollow).first
        XCTAssertNotNil(notificationOrNil)
        
        if let notification = notificationOrNil {
            let messageOrNil = provider.messages.getNotificationsMessage(for: notification)
            XCTAssertNotNil(messageOrNil)
            
            if let message = messageOrNil {
                let subjectJSON = NotificationsMessageDraft.subjectBase64JSON(parentItemMessageID: createPostEmail!.header.messageID)
                let expectedPlainTextBody =
        """
You posted:

"hello, world"

Like: mailto:ploden@gmail.com?subject=Fm%20\(Template.PlainText.likeSubject.rawValue)%20\(subjectJSON.like)&body=\(Template.PlainText.like.rawValue)
Comment: mailto:ploden@gmail.com?subject=Fm%20\(Template.PlainText.commentSubject.rawValue)%20\(subjectJSON.comment)

\(Template.PlainText.signature.rawValue)

"""
                
                XCTAssertEqual(message.plainTextBody!, expectedPlainTextBody)
            }
        }
        
        let isUnchanged = await TestHelpers.messageCountIsUnchanged(testCase: self, senderReceiver: senderReceiver, provider: &provider, config: config)
        XCTAssert(isUnchanged)
    }
    
    /*
     Don't run process until multiple messages have been downloaded.
     */
    func testBatchCreateAccountAndCreatePost() async throws {
        var uid: UInt64 = 1
        let user = EmailAddress(displayName: "Phil Loden", address: "ploden@gmail.com")!
        let theme = await (UIApplication.shared.delegate as! AppDelegate).appConfig.defaultTheme
        let settings = AppleSettings(user: user, selectedTheme: theme)
        
        var messages = MessageStore()
        
        let _ = MessageReceiverTests.loadCreateAccountEmail(testCase: self, uid: &uid, messages: &messages, host: settings.user)
        
        let senderReceiver = TestSenderReceiver()
        senderReceiver.user = user
        senderReceiver.settings = settings
        
        var provider = MailProvider(settings: settings, messages: messages)
        let config = await (UIApplication.shared.delegate as! AppDelegate).appConfig
        
        let _ = MessageReceiverTests.loadCreatePostEmail(testCase: self, uid: &uid, provider: &provider)

        await TestHelpers.processMailAndSend(config: config, sender: senderReceiver, receiver: senderReceiver, testCase: self, provider: &provider)

        XCTAssert(provider.messages.allMessages.count == 4)
                
        await TestHelpers.processMailAndSend(config: config, sender: senderReceiver, receiver: senderReceiver, testCase: self, provider: &provider)

        // one more because of notification to self
        XCTAssert(provider.messages.allMessages.count == 5)

        let follows = provider.messages.follows(followee: provider.messages.hostUser!.id)
        XCTAssertNotNil(follows.count == 1)
                        
        let selfFollow = follows.first(where: { $0.followerID == provider.messages.hostUser!.email.id } )!
        let notificationOrNil = provider.messages.notifications(ofType: Notification.self, follow: selfFollow).first
        XCTAssertNotNil(notificationOrNil)
        
        if let notification = notificationOrNil {
            let messageOrNil = provider.messages.getNotificationsMessage(for: notification)
            XCTAssertNotNil(messageOrNil)
            
            if let message = messageOrNil {                
                let expectedPlainTextBody =
                    """
            You posted:
            
            "hello, world"
            
            Like: mailto:ploden@gmail.com?subject=Fm%20Like:61FD0524-97BD-4C61-A011-D613F3E63E05@gmail.com&body=\(Template.PlainText.like.rawValue)
            Comment: mailto:ploden@gmail.com?subject=Fm%20Comment:61FD0524-97BD-4C61-A011-D613F3E63E05@gmail.com
            
            \(Template.PlainText.signature.rawValue)
            
            """
               
                XCTAssertEqual(message.plainTextBody!, expectedPlainTextBody)
            }
        }
    }
    
    func testNewLikeSelfNotification() async throws {
        let config = await (UIApplication.shared.delegate as! AppDelegate).appConfig
        var (provider, senderReceiver, uid) = await TestHelpers.defaultSetup(testCase: self)
        
        var inoutMessages: MessageStore! = provider.messages
        let _ = MessageReceiverTests.loadCreateAddFollowersEmail(testCase: self, uid: &uid, provider: &provider)
        
        inoutMessages = provider.messages
        await TestHelpers.processMailAndSend(config: config, sender: senderReceiver, receiver: senderReceiver, testCase: self, messages: &inoutMessages)
        provider = provider.new(mergingMessageStore: inoutMessages, postNotification: false)
        inoutMessages = nil
        
        let _ = MessageReceiverTests.loadCreatePostEmail(testCase: self, uid: &uid, provider: &provider)
        
        let _ = MessageReceiverTests.loadCreateLikeEmail(testCase: self, uid: &uid, provider: &provider)
        
        inoutMessages = provider.messages
        /*
        let newsFeed = MailController.newsFeedNotifications(messages: inoutMessages)
        XCTAssert(newsFeed.count > 0)
         */
        
        await TestHelpers.processMailAndSend(config: config, sender: senderReceiver, receiver: senderReceiver, testCase: self, messages: &inoutMessages)
        provider = provider.new(mergingMessageStore: inoutMessages, postNotification: false)
        inoutMessages = nil
        
        let resultOrNil = provider.messages.messages(ofType: NotificationsMessage.self).first(where: { notificationsMessage in
            notificationsMessage.notifications.contains(where: { $0 is NewLikeNotification })
        })
        
        XCTAssertNotNil(resultOrNil)
        
        if let result = resultOrNil {
            let expectedPlainTextBody =
                """
        Phil Postcards liked your post.
        
        Phil Loden:
        \"hello, world\"
        
        Phil Postcards:
        \"\(Template.PlainText.like.rawValue)\"
        
        \(Template.PlainText.signature.rawValue)
        
        """
            
            XCTAssertEqual(result.plainTextBody!, expectedPlainTextBody)
        }
        
        let isUnchanged = await TestHelpers.messageCountIsUnchanged(testCase: self, senderReceiver: senderReceiver, provider: &provider, config: config)
        XCTAssert(isUnchanged)
    }
    
    /*
     Load a create subscription email and a create post email and a create comment email. Is a notification email sent?
     */
    func testCreateSubscriptionAndCreatePostAndUpdateFollowerAndCreateComment() async throws {
        let config = await (UIApplication.shared.delegate as! AppDelegate).appConfig
        var (provider, senderReceiver, uid) = await TestHelpers.defaultSetup(testCase: self)

        let loadedCreateCommandsMessage = MessageReceiverTests.loadCreateAddFollowersEmail(testCase: self, uid: &uid, provider: &provider)
        XCTAssert(loadedCreateCommandsMessage is CreateCommandsMessage)
        
        var inoutMessages: MessageStore! = provider.messages
        
        await TestHelpers.processMailAndSend(config: config, sender: senderReceiver, receiver: senderReceiver, testCase: self, messages: &inoutMessages)
        provider = provider.new(mergingMessageStore: inoutMessages, postNotification: false)
        inoutMessages = nil
        
        let loadedCreatePostingMessage = MessageReceiverTests.loadCreatePostEmail(testCase: self, uid: &uid, provider: &provider)
        XCTAssert(loadedCreatePostingMessage is CreatePostingMessage)
        
        let loadedCreateCommentMessage = MessageReceiverTests.loadCreateCommentEmail(testCase: self, uid: &uid, provider: &provider)
        XCTAssert(loadedCreateCommentMessage is CreateCommentMessage)
        
        let comments = provider.messages.messages(ofType: CreateCommentMessage.self)
                
        XCTAssert(comments.count == 1)
                
        let expectedPlainTextBody =
        """
Phil Postcards commented on your post.

Phil Loden:
\"hello, world\"

Phil Postcards:
\"Hello back.\"

Like: mailto:ploden.postcards@gmail.com?subject=Fm%20Like:43ED17AA-EEF0-4A8C-B791-EB8C675B116E@gmail.com&body=\(Template.PlainText.like.rawValue)
Reply: mailto:ploden.postcards@gmail.com?subject=Fm%20Comment:43ED17AA-EEF0-4A8C-B791-EB8C675B116E@gmail.com

\(Template.PlainText.signature.rawValue)

"""
        
        let follows = provider.messages.follows(followee: provider.messages.hostUser!.id)
        XCTAssert(follows.count == 3)
        
        for follow in follows {
            // new comment notifications should only be sent to the author of the posting being commented on (for now)
            // should be changed to follow post on post creation 
            let count: Int = follow.followerID == provider.messages.hostUser!.email.id ? 1 : 0
            let unsentNewCommentNotificationsCount = MailController.unsentNewCommentNotifications(messages: provider.messages, for: follow).count
            XCTAssertEqual(unsentNewCommentNotificationsCount, count)
        }
        
        inoutMessages = provider.messages
        
        await TestHelpers.processMailAndSend(config: config, sender: senderReceiver, receiver: senderReceiver, testCase: self, messages: &inoutMessages)
        provider = provider.new(mergingMessageStore: inoutMessages, postNotification: false)
        inoutMessages = nil
                
        let resultOrNil = provider.messages.messages(ofType: NotificationsMessage.self).first(where: { notificationsMessage in
            notificationsMessage.notifications.contains(where: { $0 is NewCommentNotification })
        })
        
        XCTAssertNotNil(resultOrNil)
        
        if let result = resultOrNil {
            XCTAssertEqual(result.plainTextBody!, expectedPlainTextBody)
        }
    }
    
    /*
     Load a create follow email and a create post email. Is a notification message sent?
     */
    func testUnsentNewPostNotifications() async throws {
        let config = await (UIApplication.shared.delegate as! AppDelegate).appConfig
        var (provider, senderReceiver, uid) = await TestHelpers.defaultSetup(testCase: self)
        
        var inoutMessages: MessageStore! = provider.messages
        let _ = MessageReceiverTests.loadCreateAddFollowersEmail(testCase: self, uid: &uid, provider: &provider)
        
        inoutMessages = provider.messages
        await TestHelpers.processMailAndSend(config: config, sender: senderReceiver, receiver: senderReceiver, testCase: self, messages: &inoutMessages)
        provider = provider.new(mergingMessageStore: inoutMessages, postNotification: false)
        inoutMessages = nil
        
        let follows = provider.messages.follows(followee: provider.messages.hostUser!.id)
        XCTAssert(follows.count == 2)
        
        let _ = MessageReceiverTests.loadCreatePostEmail(testCase: self, uid: &uid, provider: &provider)
        
        for follow in follows {
            let unsent = MailController.unsentNewPostNotifications(messages: provider.messages, for: follow)
            XCTAssert(unsent.count == 1)
        }
    }
    
      /*
    /*
     A create invites email exists. Was a corresponding CreateInvitesMessage object created?
     */
    func testCreateInvitesMessage() throws {
        let uid: UInt64 = 1

        let incorrectUser = Address(name: "Phil Loden", address: "blah@blah.com")!
        let theme = (UIApplication.shared.delegate as! AppDelegate).appConfig.defaultTheme
        let incorrectSettings = TestSettings(user: incorrectUser, password: "", selectedTheme: theme)
        
        // Load email from file
        let createInviteEmailPath = Bundle(for: type(of: self )).path(forResource: "create_invite", ofType: "txt")!
        let incorrectCreateInviteEmail = TestHelpers.loadEmail(accountAddress: incorrectUser, withPath: createInviteEmailPath, uid: uid)

        // Sender does not match account in settings, ergo should be no create invite message
        XCTAssertNotNil(incorrectCreateInviteEmail)
        XCTAssertFalse(incorrectCreateInviteEmail is CreateInvitesMessage)
        
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let correctSettings = TestSettings(user: user, password: "", selectedTheme: theme)
        let correctCreateInviteEmail = TestHelpers.loadEmail(accountAddress: user, withPath: createInviteEmailPath, uid: uid)

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
        
        let settings = AppleSettings(user: user, selectedTheme: theme)
        let provider = MailProvider(settings: settings, messages: messages)
        let config = (UIApplication.shared.delegate as! AppDelegate).appConfig
        let results = MailController.processMail(config: config, sender: provider, receiver: provider, messages: messages)
        
        let expectedPlainTextBody =
        """
Phil Loden has invited you to their friendlymail. Follow to receive their updates and photos:

Follow Daily: mailto:ploden@gmail.com?subject=Fm&body=Follow%20daily
Follow Weekly: mailto:ploden@gmail.com?subject=Fm&body=Follow%20weekly
Follow Monthly: mailto:ploden@gmail.com?subject=Fm&body=Follow%20monthly
Follow Realtime: mailto:ploden@gmail.com?subject=Fm&body=Follow%20realtime

\(Template.PlainText.signature.rawValue)

"""
        
        XCTAssert(results.drafts.count > 0)
        let match = results.drafts.first { $0.plainTextBody == expectedPlainTextBody }
        XCTAssertNotNil(match)
        XCTAssertNotNil(match!.subject)
    }

    ///  Scenario: a follower is invited, and accepts the invite.
    func testCreateInvitesAndCreateSubscription() throws {
        var uid: UInt64 = 1
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let theme = (UIApplication.shared.delegate as! AppDelegate).appConfig.defaultTheme
        let settings = AppleSettings(user: user, selectedTheme: theme)

        var messages = MessageStore()

        // Load create invites email from file
        MessageReceiverTests.loadCreateInvitesEmail(testCase: self, uid: &uid, accountAddress: user, messages: &messages)
        
        let createInvitesMessage = messages.allMessages.first as! CreateInvitesMessage
        
        // Load create subscription email from file
        MessageReceiverTests.loadCreateSubscriptionEmail(testCase: self, uid: &uid, accountAddress: user, messages: &messages)
        
        let message = messages.allMessages.first { $0 is CreateSubscriptionMessage }
        
        // Test for create subscription message
        XCTAssertNotNil(message)
        XCTAssert(message is CreateSubscriptionMessage)
        
        // Test for subscription
        let createSubscriptionMessage = message as! CreateSubscriptionMessage
        let subscription = createSubscriptionMessage.subscription
        let expectedFollower = Address(name: "Phil Loden", address: "ploden.postcards@gmail.com")
        XCTAssertEqual(expectedFollower, subscription.follower)
        
        // Test for subscriptions
        let subscriptions = MailController.subscriptions(forAddress: Address(name: settings.user.name, address: settings.user.address)!, messages: messages)
        XCTAssert(subscriptions.contains(subscription))
        XCTAssert(subscription.follower == createInvitesMessage.invitees.first)
    }
    
    /*
     Load a create subscription email and a create post email and a create like email. Is a notification email sent?
     */
    func testCreateSubscriptionAndCreatePostAndUpdateFollowerAndCreateLike() throws {
        var uid: UInt64 = 1
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let theme = (UIApplication.shared.delegate as! AppDelegate).appConfig.defaultTheme
        let settings = AppleSettings(user: user, selectedTheme: theme)
        
        var messages = MessageStore()
        
        // Load create subscription email from file
        MessageReceiverTests.loadCreateSubscriptionEmail(testCase: self, uid: &uid, accountAddress: user, messages: &messages)
        
        // Load create post email from file
        MessageReceiverTests.loadCreatePostEmail(testCase: self, uid: &uid, accountAddress: user, messages: &messages)
        
        let senderReceiver = TestSenderReceiver()
        senderReceiver.user = user
        senderReceiver.settings = settings
        
        let provider = MailProvider(settings: settings, messages: messages)
        
        // Load create like email from file
        let config = (UIApplication.shared.delegate as! AppDelegate).appConfig
        messages = MailController.processMail(config: config, sender: provider, receiver: provider, messages: messages).messageStore
        MessageReceiverTests.loadCreateLikeEmail(testCase: self, uid: &uid, accountAddress: user, messages: &messages)
        
        // Test that the message fields are populated correctly
        
        let expectedPlainTextBody =
        """
ploden.postcards@gmail.com liked your post.

ploden@gmail.com:
\"hello, world\"

ploden.postcards@gmail.com:
\"\(Template.PlainText.like.rawValue)\"

\(Template.PlainText.signature.rawValue)

"""
        
        let results = MailController.processMail(config: config, sender: provider, receiver: provider, messages: messages)
        //let match = results.drafts.last { $0.plainTextBody == expectedPlainTextBody }
        let match = results.drafts.last!
        let actualPlainTextBody = results.drafts.last!.plainTextBody
        XCTAssert(actualPlainTextBody == expectedPlainTextBody)
        //XCTAssertNotNil(match)
        XCTAssertNotNil(match.subject)
        XCTAssertNotNil(match.friendlyMailHeaders)
    }
    */
}

/*
 Scenarios
 
 User: person using friendlymail
 
 ✅ A follower is invited, and accepts the invite.
 ✅ Follower is added
 Follower unfollows user
 Follower changes update frequency 
 
 User creates post
 User creates post with photo
 Follower likes post
 Follower comments on post
 User replies to comment
 User likes comment
 Follower replies to user's comment
 
 User selects theme
 User changes update frequency
 */

/*
 Create account:
 1. ✅ Send useradd command
    Receive success response
 2. ✅ Send duplicate useradd command
    Receive error response
 3. ✅ Send useradd command from wrong email
    Receive error response
 4. Send useradd command
    Follow self message is created
 
 Set profile pic:
 1. ✅ Send usermod command with photo attachment
    Receive success response
 
 follow:
 1. ✅ Send add follower command
    Receive command response
 
 Create text post and send notifications:
 1. Send create post message
    Author receives new post notification message
    Follower receives new post notification message

 Create photo post and send notifications:
 1. Send create post message
    Author receives new post notification message
    Follower receives new post notification message

 Create like and send notifications:
 1. Send create like message
    Post author receives new like notification message

 Create comment and send notifications:
 1. Send create comment message
    Post author receives new comment notification message
    Comment author receives new comment notification message

 */
