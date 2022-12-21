//
//  MailControllerTests.swift
//  friendly-mailTests
//
//  Created by Philip Loden on 9/2/21.
//

import XCTest
@testable import friendly_mail_ios
@testable import friendly_mail_core

class MailControllerTests: XCTestCase {

    func testCreateAccount() throws {
        var uid: UInt64 = 1
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let theme = (UIApplication.shared.delegate as! AppDelegate).appConfig.defaultTheme
        let settings = AppleSettings(user: user, selectedTheme: theme)
        
        var messages = MessageStore()
        
        MessageReceiverTests.loadCreateAccountEmail(testCase: self, uid: &uid, messages: &messages)
        
        let senderReceiver = TestSenderReceiver()
        senderReceiver.user = user
        senderReceiver.settings = settings
        
        var provider = MailProvider(settings: settings, messages: messages)
        let config = (UIApplication.shared.delegate as! AppDelegate).appConfig
        TestHelpers.processMailAndSend(config: config, sender: senderReceiver, receiver: senderReceiver, testCase: self, provider: &provider)

        XCTAssert(senderReceiver.sentMessages.allMessages.count == 1)
        XCTAssert(provider.messages.allMessages.count == 2)
        
        TestHelpers.processMailAndSend(config: config, sender: senderReceiver, receiver: senderReceiver, testCase: self, provider: &provider)

        XCTAssert(senderReceiver.sentMessages.allMessages.count == 1)
        XCTAssert(provider.messages.allMessages.count == 2)

        let expectedPlainTextBody =
            """
    friendly-mail: create account: account created for ploden@gmail.com
    
    friendly-mail, an open-source, email-based, alternative social network
    
    """
        
        let sentMessage = senderReceiver.sentMessages.allMessages.first!
        
        XCTAssert(sentMessage.plainTextBody == expectedPlainTextBody)
        XCTAssertNil(sentMessage.htmlBody)
    }
    
    func testCreateAccountAndSendResponse() throws {
        var uid: UInt64 = 1
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let theme = (UIApplication.shared.delegate as! AppDelegate).appConfig.defaultTheme
        let settings = AppleSettings(user: user, selectedTheme: theme)
        
        var messages = MessageStore()
                
        let senderReceiver = TestSenderReceiver()
        senderReceiver.user = user
        senderReceiver.settings = settings
        
        let provider = MailProvider(settings: settings, messages: messages)
        
        let config = (UIApplication.shared.delegate as! AppDelegate).appConfig
        
        MessageReceiverTests.loadCreateAccountEmailAndSendResponse(config: config,
                                                                   sender: senderReceiver,
                                                                   receiver: senderReceiver,
                                                                   testCase: self,
                                                                   uid: &uid,
                                                                   messages: &messages)

        let account = messages.account
        
        XCTAssertNotNil(account)
    }
    
    func testAccountAlreadyExists() throws {
        var uid: UInt64 = 1
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let theme = (UIApplication.shared.delegate as! AppDelegate).appConfig.defaultTheme
        let settings = AppleSettings(user: user, selectedTheme: theme)
                        
        let senderReceiver = TestSenderReceiver()
        senderReceiver.user = user
        senderReceiver.settings = settings
        
        var provider = MailProvider(settings: settings, messages: MessageStore())
        
        let config = (UIApplication.shared.delegate as! AppDelegate).appConfig
        
        var inoutMessages: MessageStore! = provider.messages
        
        MessageReceiverTests.loadCreateAccountEmailAndSendResponse(config: config,
                                                                   sender: senderReceiver,
                                                                   receiver: senderReceiver,
                                                                   testCase: self,
                                                                   uid: &uid,
                                                                   messages: &inoutMessages)

        provider = provider.new(mergingMessageStores: inoutMessages, postNotification: false)
        inoutMessages = nil
        
        let account = provider.messages.account
        
        XCTAssertNotNil(account)
        
        let path = Bundle(for: type(of: self )).path(forResource: "create_command_create_account_2", ofType: "txt")!
        TestHelpers.loadEmail(account: account, withPath: path, uid: &uid, provider: &provider)
        inoutMessages = provider.messages
        TestHelpers.processMailAndSend(config: config, sender: senderReceiver, receiver: senderReceiver, testCase: self, messages: &inoutMessages)
        provider = provider.new(mergingMessageStores: inoutMessages, postNotification: false)
        inoutMessages = nil
        
        let sent = senderReceiver.sentMessages
        
        XCTAssertNotNil(account)
        
        let result = sent.allMessages.first(where: { $0 is CommandResultMessage }) as! CommandResultMessage
        XCTAssert(result.commandResult.exitCode != .success)
        
        let expectedPlainTextBody =
            """
    friendly-mail: create account: account already exists for ploden@gmail.com
    
    friendly-mail, an open-source, email-based, alternative social network
    
    """
        
        XCTAssert(result.plainTextBody! == expectedPlainTextBody)
    }
    
    func testCreateAccountPermissionDenied() throws {
        var uid: UInt64 = 1
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let theme = (UIApplication.shared.delegate as! AppDelegate).appConfig.defaultTheme
        let settings = AppleSettings(user: user, selectedTheme: theme)
                        
        let senderReceiver = TestSenderReceiver()
        senderReceiver.user = user
        senderReceiver.settings = settings
        
        var provider = MailProvider(settings: settings, messages: MessageStore())
        
        let config = (UIApplication.shared.delegate as! AppDelegate).appConfig
        
        var inoutMessages: MessageStore! = provider.messages
        
        MessageReceiverTests.loadCreateAccountEmailAndSendResponse(config: config,
                                                                   sender: senderReceiver,
                                                                   receiver: senderReceiver,
                                                                   testCase: self,
                                                                   uid: &uid,
                                                                   messages: &inoutMessages)

        provider = provider.new(mergingMessageStores: inoutMessages, postNotification: false)
        inoutMessages = nil
        
        let path = Bundle(for: type(of: self )).path(forResource: "create_command_permission_denied", ofType: "txt")!
        inoutMessages = provider.messages
        TestHelpers.loadEmail(account: inoutMessages.account, withPath: path, uid: &uid, provider: &provider)
        
        inoutMessages = provider.messages
        TestHelpers.processMailAndSend(config: config, sender: senderReceiver, receiver: senderReceiver, testCase: self, messages: &inoutMessages)
        provider = provider.new(mergingMessageStores: inoutMessages, postNotification: false)
        inoutMessages = nil

        let result = senderReceiver.sentMessages.allMessages.first(where: { $0 is CommandResultMessage }) as! CommandResultMessage
        
        XCTAssert(result.commandResult.exitCode != .success)
        
        let expectedPlainTextBody =
            """
    friendly-mail: create account: permission denied
    
    friendly-mail, an open-source, email-based, alternative social network
    
    """
        
        XCTAssert(result.plainTextBody! == expectedPlainTextBody)
    }
    
    /*
    func testNewPostFollowerNotifications() throws {
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
        
        let config = (UIApplication.shared.delegate as! AppDelegate).appConfig

        let expectation = XCTestExpectation(description: "Wait for process mail.")
        MailController.getAndProcessAndSendMail(config: config, sender: senderReceiver, receiver: senderReceiver, messages: messages) { error, updatedMessages in
            // Load create like email from file
            messages = updatedMessages
            MessageReceiverTests.loadCreateLikeEmail(testCase: self, uid: &uid, accountAddress: user, messages: &messages)
                    
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
            
            let newsFeed = MailController.newsFeedNotifications(messages: messages)
            XCTAssert(newsFeed.count > 0)
            
            let results = MailController.processMail(config: config, sender: provider, receiver: provider, messages: messages)
            let match = results.drafts.first { $0.plainTextBody == expectedPlainTextBody }
            XCTAssertNotNil(match)
            XCTAssertNotNil(match!.subject)
            expectation.fulfill()
        }
        let _ = XCTWaiter.wait(for: [expectation], timeout: 2.0)
    }
    
    /*
     Load a create subscription email and a create post email and a create comment email. Is a notification email sent?
     */
    func testCreateSubscriptionAndCreatePostAndUpdateFollowerAndCreateComment() throws {
        var uid: UInt64 = 1
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let theme = (UIApplication.shared.delegate as! AppDelegate).appConfig.defaultTheme
        let settings = AppleSettings(user: user, selectedTheme: theme)

        var messages = MessageStore()

        // Load create subscription email from file
        MessageReceiverTests.loadCreateSubscriptionEmail(testCase: self, uid: &uid, accountAddress: user, messages: &messages)
                
        // Load create post email from file
        MessageReceiverTests.loadCreatePostEmail(testCase: self, uid: &uid, accountAddress: user, messages: &messages)
        
        // Load create comment email from file
        MessageReceiverTests.loadCreateCommentEmail(testCase: self, uid: &uid, accountAddress: user, messages: &messages)
        
        let comments = messages.allMessages.compactMap { $0 as? CreateCommentMessage }
        
        XCTAssert(comments.count > 0)
        
        // Test that the message fields are populated correctly
        
        let senderReceiver = TestSenderReceiver()
        senderReceiver.user = user
        senderReceiver.settings = settings
        
        let expectedPlainTextBody =
        """
ploden.postcards@gmail.com commented on your post.

ploden@gmail.com
\"hello, world\"

ploden.postcards@gmail.com
\"Hello back.\"

Like: mailto:ploden.postcards@gmail.com?subject=Fm%20Like:43ED17AA-EEF0-4A8C-B791-EB8C675B116E@gmail.com&body=👍🏻
Reply: mailto:ploden.postcards@gmail.com?subject=Fm%20Comment:43ED17AA-EEF0-4A8C-B791-EB8C675B116E@gmail.com

friendly-mail, an open-source, email-based, alternative social network

"""
   
        let provider = MailProvider(settings: settings, messages: messages)
        let config = (UIApplication.shared.delegate as! AppDelegate).appConfig
        let results = MailController.processMail(config: config, sender: provider, receiver: provider, messages: messages)
        let match = results.drafts.first { $0.plainTextBody == expectedPlainTextBody }
        XCTAssertNotNil(match)
        XCTAssertNotNil(match!.subject)
    }
    
    /*
     Load a create subscription email and a create post email. Is an UpdateFollowerMessage sent?
     */
    func testCreateSubscriptionAndCreatePostAndUpdateFollower() throws {
        var uid: UInt64 = 1
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let theme = (UIApplication.shared.delegate as! AppDelegate).appConfig.defaultTheme
        let settings = AppleSettings(user: user, selectedTheme: theme)

        var messages = MessageStore()

        // Load create subscription email from file
        MessageReceiverTests.loadCreateSubscriptionEmail(testCase: self, uid: &uid, accountAddress: user, messages: &messages)
                
        // Load create post email from file
        MessageReceiverTests.loadCreatePostEmail(testCase: self, uid: &uid, accountAddress: user, messages: &messages)
        
        // Test for UpdateFollowerMessage
        let subscription = MailController.subscriptions(forAddress: settings.user, messages: messages).first!
        
        let unsent = MailController.unsentNewPostNotifications(messages: messages, for: subscription).first
        
        XCTAssert(unsent != nil)
        
        // Test that the message fields are populated correctly
        
        let provider = MailProvider(settings: settings, messages: messages)
        let config = (UIApplication.shared.delegate as! AppDelegate).appConfig
        let results = MailController.processMail(config: config, sender: provider, receiver: provider, messages: messages)
        
        let expectedPlainTextBody =
        """
ploden@gmail.com posted:

"hello, world"

Like: mailto:ploden@gmail.com?subject=Fm%20Like:61FD0524-97BD-4C61-A011-D613F3E63E05@gmail.com&body=👍🏻
Comment: mailto:ploden@gmail.com?subject=Fm%20Comment:61FD0524-97BD-4C61-A011-D613F3E63E05@gmail.com

friendly-mail, an open-source, email-based, alternative social network

"""
        
        let match = results.drafts.first { $0.plainTextBody == expectedPlainTextBody }
        XCTAssertNotNil(match)
        XCTAssertNotNil(match!.subject)
    }
    
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
Phil Loden has invited you to their friendly-mail. Follow to receive their updates and photos:

Follow Daily: mailto:ploden@gmail.com?subject=Fm&body=Follow%20daily
Follow Weekly: mailto:ploden@gmail.com?subject=Fm&body=Follow%20weekly
Follow Monthly: mailto:ploden@gmail.com?subject=Fm&body=Follow%20monthly
Follow Realtime: mailto:ploden@gmail.com?subject=Fm&body=Follow%20realtime

friendly-mail, an open-source, email-based, alternative social network

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
     A create add followers email exists. Was a corresponding CreateAddFollowersMessage object created?
     */
    func testCreateAddFollowersMessage() throws {
        // Load email from file
        let path = Bundle(for: type(of: self )).path(forResource: "create_add_followers", ofType: "txt")!

        let uid: UInt64 = 1
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let theme = (UIApplication.shared.delegate as! AppDelegate).appConfig.defaultTheme
        let correctSettings = AppleSettings(user: user, selectedTheme: theme)
        let correctMessage = TestHelpers.loadEmail(accountAddress: user, withPath: path, uid: uid)
        
        // Test for create subscription message
        XCTAssertNotNil(correctMessage)
        XCTAssert(correctMessage is CreateAddFollowersMessage)
        
        // Test for subscription
        let createSubscriptionMessage = correctMessage as! CreateAddFollowersMessage
        let subscription = createSubscriptionMessage.subscriptions.first!
        let expectedFollower = Address(name: "Phil Loden", address: "ploden.postcards@gmail.com")
        XCTAssertEqual(expectedFollower, subscription.follower)
        
        var messages = MessageStore()

        messages = messages.addingMessage(message: createSubscriptionMessage, messageID: createSubscriptionMessage.header.messageID)
        
        // Test for subscriptions
        let subscriptions = MailController.subscriptions(forAddress: Address(name: correctSettings.user.name, address: correctSettings.user.address)!, messages: messages)
        XCTAssert(subscriptions.contains(subscription))
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
\"👍🏻\"

friendly-mail, an open-source, email-based, alternative social network

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
    
    ///  Scenario: an unsupported command is received, and replied to
    func testCreateCommandsAndCommandResult() throws {
        var uid: UInt64 = 1
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let theme = (UIApplication.shared.delegate as! AppDelegate).appConfig.defaultTheme
        let settings = AppleSettings(user: user, selectedTheme: theme)

        var messages = MessageStore()

        // Load create invites email from file
        let path = Bundle(for: type(of: self )).path(forResource: "command_not_found", ofType: "txt")!
        let email = TestHelpers.loadEmail(accountAddress: user, withPath: path, uid: uid)!
        
        messages = messages.addingMessage(message: email, messageID: email.header.messageID)

        let provider = MailProvider(settings: settings, messages: messages)

        let config = (UIApplication.shared.delegate as! AppDelegate).appConfig
        let results = MailController.processMail(config: config, sender: provider, receiver: provider, messages: messages)

        let message = messages.allMessages.first { $0 is CreateCommandsMessage }
        
        // Test for create subscription message
        XCTAssertNotNil(message)
        XCTAssert(message is CreateCommandsMessage)
        
        let createCommandsMessage = message as! CreateCommandsMessage
        XCTAssert(createCommandsMessage.commands.first!.commandType == .unknown)
        
        XCTAssert(results.drafts.count == 1)
        let draft = results.drafts.first!
        
        let expectedPlainTextBody =
        """
friendly-mail: aoeu: command not found

friendly-mail, an open-source, email-based, alternative social network

"""
        
        XCTAssert(draft.plainTextBody == expectedPlainTextBody)
    }
    
    ///  Scenario: an unsupported command is received, and replied to only once 
    func testCreateCommandsAndCommandResultNoDuplicates() throws {
        var uid: UInt64 = 1
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let theme = (UIApplication.shared.delegate as! AppDelegate).appConfig.defaultTheme
        let settings = AppleSettings(user: user, selectedTheme: theme)

        var messages = MessageStore()

        // Load create invites email from file
        let path = Bundle(for: type(of: self )).path(forResource: "command_not_found", ofType: "txt")!
        let email = TestHelpers.loadEmail(accountAddress: user, withPath: path, uid: uid)!
        uid = uid + 1
        
        messages = messages.addingMessage(message: email, messageID: email.header.messageID)
        
        let commandResultPath = Bundle(for: type(of: self )).path(forResource: "command_not_found_command_result_decoded", ofType: "txt")!
        let commandResultEmail = TestHelpers.loadEmail(accountAddress: user, withPath: commandResultPath, uid: uid)!
        
        messages = messages.addingMessage(message: commandResultEmail, messageID: commandResultEmail.header.messageID)
        
        let provider = MailProvider(settings: settings, messages: messages)

        let config = (UIApplication.shared.delegate as! AppDelegate).appConfig
        let results = MailController.processMail(config: config, sender: provider, receiver: provider, messages: messages)
        
        XCTAssert(results.drafts.count == 0)
    }
    */
}

/*
 Scenarios
 
 User: person using friendly-mail
 
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
 1. ✅ Send create account command
    Receive success response
 2. ✅ Send duplicate create account command
    Receive error response
 3. ✅ Send create account command from wrong email
    Receive error response
 
 Set profile pic:
 1. Send set profile pic command with photo attachment
    Receive success response 
 
 Add follower:
 1. Send add follower command
    Receive command response
 
 Create post:
 1. Send create post message
    Receive new post message
 
 
 */
