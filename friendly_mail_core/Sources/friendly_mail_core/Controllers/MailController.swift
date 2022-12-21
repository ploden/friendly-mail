//
//  MailController.swift
//  friendly-mail
//
//  Created by Philip Loden on 7/24/21.
//

import Foundation
//import os
//import mailcore2

enum FMError: Error {
    case unknown
}

enum HeaderKey: String {
    case type = "t"
    case notificationCreateCommentMessageID = "n_cc_mid"
    case notificationCreatePostMessageID = "n_cp_mid"
    case notificationCreateLikeMessageID = "n_cl_mid"
    case createInvitesMessageID = "ci_mid"
    case createCommandsMessageID = "cc_mid"
    case base64JSON = "json"
}

public typealias NewLikeNotificationWithMessages = (notification: NewLikeNotification, createLikeMessage: CreateLikeMessage, createPostMessage: CreatePostingMessage)
public typealias NewPostNotificationWithMessage = (notification: NewPostNotification, createPostMessage: CreatePostingMessage)
public typealias NewCommentNotificationWithMessages = (notification: NewCommentNotification, createCommentMessage: CreateCommentMessage, createPostMessage: CreatePostingMessage)

public class MailController {
    //static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "misc")
    
    public static func newsFeedNotifications(messages: MessageStore) -> [Any] {
        let account = messages.account!
        
        let sentLikes = MailController.sentNewLikeNotifications(account: account, messages: messages)
        let unsentLikes = MailController.unsentNewLikeNotifications(messages: messages)
        let sentAndUnsentLikes = sentLikes.union(unsentLikes)
        let newLikeNotificationsWithMessages = MailController.newLikeNotificationWithMessages(for: Array(sentAndUnsentLikes), messages: messages)
        
        let sentComments = MailController.sentNewCommentNotifications(account: account, messages: messages)
        let unsentComments = MailController.unsentNewCommentNotifications(messages: messages)
        let sentAndUnsentComments = sentComments.union(unsentComments)
        let newCommentNotificationsWithMessages = MailController.newCommentNotificationWithMessages(for: Array(sentAndUnsentComments), messages: messages)
        
        var combined: [Any] = newLikeNotificationsWithMessages + newCommentNotificationsWithMessages
        combined.sort { first, second in
            if
                let firstDate = (first as? NewLikeNotificationWithMessages)?.createLikeMessage.header.date ?? (first as? NewCommentNotificationWithMessages)?.createCommentMessage.header.date,
                let secondDate = (second as? NewLikeNotificationWithMessages)?.createLikeMessage.header.date ?? (second as? NewCommentNotificationWithMessages)?.createCommentMessage.header.date
            {
                return firstDate < secondDate
            }
            return false
        }
        return combined
    }
    
    public static func getAndProcessAndSendMail(config: AppConfig,
                                                sender: MessageSender,
                                                receiver: MessageReceiver,
                                                messages: MessageStore,
                                                logger: Logger?,
                                                completion: @escaping (Error?, MessageStore) -> ())
    {
        MailController.getAndProcessMail(config: config, sender: sender, receiver: receiver, messages: messages, logger: logger) { error, messagesAfterGetAndProcessMail, drafts in
            if let error = error {
                completion(error, messages)
            } else {
                DispatchQueue.global(qos: .userInteractive).async {
                    let downloadGroup = DispatchGroup()
                    
                    var updatedMessages = messagesAfterGetAndProcessMail
                    
                    var outerError: Error? = nil
                    var toMoveToInbox = [MessageID]()
                    var sentCount = 0
                    
                    for draft in drafts {
                        downloadGroup.enter()
                        sender.sendMessage(to: draft.to, subject: draft.subject, htmlBody: draft.htmlBody, plainTextBody: draft.plainTextBody, friendlyMailHeaders: draft.friendlyMailHeaders) { error, sentMessageID in
                            sentCount += sentMessageID == nil ? 0 : 1
                            
                            if
                                let account = updatedMessages.account,
                                let sentMessageID = sentMessageID,
                                draft.to.contains(account.user)
                            {
                                toMoveToInbox.append(sentMessageID)
                            }
                            outerError = error ?? outerError
                            downloadGroup.leave()
                        }
                    }
                    downloadGroup.wait()
                    
                    logger?.log(message: "getAndProcessAndSendMail: sent \(sentCount) messages.")
                    
                    var movedCount = 0
                    
                    for toMoveMessageID in toMoveToInbox {
                        downloadGroup.enter()
                        
                        receiver.fetchFriendlyMailMessage(messageID: toMoveMessageID) { fetchError, fetchedMessage in
                            if let fetchedMessage = fetchedMessage {
                                downloadGroup.enter()
                                sender.moveMessageToInbox(message: fetchedMessage) { moveError in
                                    movedCount += moveError == nil ? 1 : 0
                                    downloadGroup.leave()
                                }
                            }
                            downloadGroup.leave()
                        }
                    }
                    logger?.log(message: "getAndProcessAndSendMail: moved \(sentCount) messages.")
                    
                    downloadGroup.enter() // for get mail
                    receiver.downloadFriendlyMailMessages() { error, messages in
                        outerError = error ?? outerError
                        if let messages = messages {
                            updatedMessages = updatedMessages.merging(messageStore: messages)
                        }
                        downloadGroup.leave()
                    }
                    
                    downloadGroup.notify(queue: DispatchQueue.main) {
                        completion(outerError, updatedMessages)
                    }
                }
            }
        }
    }
    
    static func getAndProcessMail(config: AppConfig, sender: MessageSender, receiver: MessageReceiver, messages: MessageStore, logger: Logger?, completion: @escaping (Error?, MessageStore, [MessageDraft]) -> ()) {
        // first get sent mail, or we might send duplicates. Or do we? Sent messages are tagged friendly-mail.
        
        // fetch messages with nil bodies
        
        var updatedMessages = messages
                
        DispatchQueue.global(qos: .default).async {
            receiver.downloadFriendlyMailMessages() { error, messages in
                if let messages = messages, error == nil {
                    let previousCount = updatedMessages.numMessages
                    updatedMessages = updatedMessages.merging(messageStore: messages)
                    let currentCount = updatedMessages.numMessages
                    logger?.log(message: "getAndProcessMail: getMail: downloaded \(currentCount - previousCount) messages.")
                    
                    let messagesToFulfill = updatedMessages.allMessages.filter {
                        $0.shouldFetch
                    }
                    
                    let downloadGroup = DispatchGroup()
                    
                    var fetchCount = 0
                    
                    downloadGroup.enter()
                    
                    for message in messagesToFulfill {
                        downloadGroup.enter()
                        receiver.fetchMessage(uidWithMailbox: message.uidWithMailbox) { fetchError, fetchedMessage in
                            if let fetchedMessage = fetchedMessage {
                                fetchCount += 1
                                updatedMessages = updatedMessages.addingMessage(message: fetchedMessage, messageID: message.header.messageID)
                                logger?.log(message: "getAndProcessMail: fetchMessage: downloaded \(type(of: fetchedMessage)) message.")
                            } else if let fetchError = fetchError {
                                logger?.log(message: "getAndProcessMail: fetchMessage: error fetching message with uid: \(message.uidWithMailbox.UID). error: \(fetchError.localizedDescription)")
                            }
                            downloadGroup.leave()
                        }
                    }
                    
                    downloadGroup.leave()
                    
                    downloadGroup.notify(queue: DispatchQueue.main) {
                        logger?.log(message: "getAndProcessMail: fetched \(fetchCount) messages.")
                        let errorMessagesDrafts = processMail(config: config, sender: sender, receiver: receiver, messages: updatedMessages)
                        
                        completion(errorMessagesDrafts.error, errorMessagesDrafts.messageStore, errorMessagesDrafts.drafts)
                    }
                } else {
                    completion(error, updatedMessages, [])
                }
            }
        }
    }
    
    /*
     Process mail should only be used on a complete message store. Create account, etc. 
     */
    static func processMail(config: AppConfig, sender: MessageSender, receiver: MessageReceiver, messages: MessageStore) -> (error: Error?, messageStore: MessageStore, drafts: [MessageDraft]) {
        var drafts = [MessageDraft]()
        
        let account = messages.account
        let prefs = messages.preferences!
        let theme = config.themes.first { $0.identifier == prefs.selectedThemeID } ?? config.defaultTheme
        
        // handle commands
        let host = account?.user ?? receiver.address
        let unhandledCommands = MailController.unhandledCommands(messages: messages, host: host)
                
        let resultTemplate = CommandResultMessageTemplate(theme: theme)
        
        unhandledCommands.forEach {
            let commandsMessage = messages.getMessage(for: $0.createCommandsMessageID) as! CreateCommandsMessage
            
            let result = MailController.handle(createCommandsMessage: commandsMessage, command: $0, messages: messages, host: host)
            
            let plainText = resultTemplate.populatePlainText(with: result)!
            let plainTextBody = "\(plainText)\n\(SignatureTemplate(theme: theme).populatePlainText()!)"
            let subject = resultTemplate.populateSubject(with: result)!
            let html = resultTemplate.populateHTML(with: result)
            
            var friendlyMailHeaders = [
                HeaderKeyValue(key: HeaderKey.createCommandsMessageID.rawValue, $0.createCommandsMessageID),
            ]
            
            if result is CreateAccountSucceededCommandResult {
                friendlyMailHeaders.append(HeaderKeyValue(key: HeaderKey.type.rawValue, value: FriendlyMailMessageType.createAccountSucceededCommandResult.rawValue))
            } else {
                friendlyMailHeaders.append(HeaderKeyValue(key: HeaderKey.type.rawValue, value: FriendlyMailMessageType.commandResult.rawValue))
            }
            
            let dict: [String:CommandResult] = ["commandResult": result]
            
            let jsonData = try! JSONEncoder().encode(dict)
            let jsonDataString = String(data: jsonData, encoding: .utf8)!
            print(jsonDataString)

            let base64JSONString = jsonData.base64EncodedString()
            friendlyMailHeaders.append(HeaderKeyValue(key: HeaderKey.base64JSON.rawValue, base64JSONString))
            
            let draft = MessageDraft(to: [commandsMessage.header.fromAddress], subject: subject, htmlBody: html, plainTextBody: plainTextBody, friendlyMailHeaders: friendlyMailHeaders)
            drafts.append(draft)
        }
        
        // can only proceed if we have an account
        guard let account = account else {
            return (error: nil, messageStore: messages, drafts: drafts)
        }
        
        // send invites
        let unsentInvites = MailController.unsentInvites(inviter: account.user, messages: messages)
        
        let template = InviteMessageTemplate(theme: theme)
        
        unsentInvites.forEach {
            let plainText = template.populatePlainText(with: $0)!
            let subject = template.populateSubject(with: $0)!
            let html = template.populateHTML(with: $0)!
            
            let friendlyMailHeaders = [
                HeaderKeyValue(key: HeaderKey.type.rawValue, value: FriendlyMailMessageType.invite.rawValue),
                HeaderKeyValue(key: HeaderKey.createInvitesMessageID.rawValue, $0.createInvitesMessageID)
            ]
            
            let draft = MessageDraft(to: [$0.invitee], subject: subject, htmlBody: html, plainTextBody: plainText, friendlyMailHeaders: friendlyMailHeaders)
            drafts.append(draft)
        }
        
        // send notifications to followers
        let subscriptions = MailController.subscriptions(forAddress: account.user, messages: messages)
        
        for subscription in subscriptions {
            let unsentNewPostNotifications = MailController.unsentNewPostNotifications(messages: messages, for: subscription )
            
            if unsentNewPostNotifications.count > 0 {
                let template = NewPostNotificationTemplate(theme: theme)
                
                let textForUnsentNewPostNotifications: [String] = unsentNewPostNotifications.compactMap { unsentNewPostNotification in
                    return template.populatePlainText(with: unsentNewPostNotification.createPostMessage.post, notification: unsentNewPostNotification.notification, subscription: subscription)
                }
                
                var joined = textForUnsentNewPostNotifications.joined(separator: "\n\n")
                
                joined += "\n\(SignatureTemplate(theme: theme).populatePlainText()!)"
                
                var headers = [HeaderKeyValue]()
                
                unsentNewPostNotifications.forEach {
                    return headers.append(HeaderKeyValue(key: HeaderKey.notificationCreatePostMessageID.rawValue, value: $0.createPostMessage.header.messageID))
                }
                
                headers.append(HeaderKeyValue(key: HeaderKey.type.rawValue, value: FriendlyMailMessageType.notifications.rawValue))
                
                if
                    let first = unsentNewPostNotifications.first,
                    let subject = template.populateSubject(with: first.createPostMessage.post, notification: first.notification, subscription: subscription)
                {
                    let html = template.populateHTML(with: first.createPostMessage.post, notification: first.notification, subscription: subscription)
                    let draft = MessageDraft(to: [subscription.follower], subject: subject, htmlBody: html, plainTextBody: joined, friendlyMailHeaders: headers)
                    drafts.append(draft)
                }
            }
        }
        
        // send new comment notifications to me
        let unsentNewCommentNotifications = MailController.unsentNewCommentNotifications(messages: messages)
        let unsentNewCommentNotificationsWithMessages = MailController.newCommentNotificationWithMessages(for: Array(unsentNewCommentNotifications), messages: messages)
        
        for unsent in unsentNewCommentNotificationsWithMessages {
            let template = NewCommentNotificationTemplate(theme: theme)
            
            let plainText = template.populatePlainText(with: unsent)
            
            let body = "\(plainText ?? "")\n\(SignatureTemplate(theme: theme).populatePlainText()!)"
            
            var headers = [HeaderKeyValue]()
            
            unsentNewCommentNotificationsWithMessages.forEach {
                return headers.append(HeaderKeyValue(key: HeaderKey.notificationCreateCommentMessageID.rawValue, value: $0.createCommentMessage.header.messageID))
            }
            
            headers.append(HeaderKeyValue(key: HeaderKey.type.rawValue, value: FriendlyMailMessageType.notifications.rawValue))
            
            if let subject = template.populateSubject(with: unsent) {
                let draft = MessageDraft(to: [account.user], subject: subject, htmlBody: nil, plainTextBody: body, friendlyMailHeaders: headers)
                drafts.append(draft)
            }
        }
        
        // send new like notifications to me
        let unsentNewLikeNotifications = MailController.unsentNewLikeNotifications(messages: messages)
        let unsentNewLikeNotificationsWithMessages = MailController.newLikeNotificationWithMessages(for: Array(unsentNewLikeNotifications), messages: messages)
        
        for unsent in unsentNewLikeNotificationsWithMessages {
            let template = NewLikeNotificationTemplate(theme: theme)
            
            let plainText = template.populatePlainText(notification: unsent.notification, createLikeMessage: unsent.createLikeMessage, createPostMessage: unsent.createPostMessage)

            let body = "\(plainText ?? "")\n\(SignatureTemplate(theme: theme).populatePlainText()!)"
            
            var headers = [HeaderKeyValue]()
            
            unsentNewLikeNotificationsWithMessages.forEach {
                return headers.append(HeaderKeyValue(key: HeaderKey.notificationCreateLikeMessageID.rawValue, value: $0.createLikeMessage.header.messageID))
            }
            
            headers.append(HeaderKeyValue(key: HeaderKey.type.rawValue, value: FriendlyMailMessageType.notifications.rawValue))
            
            if let subject = template.populateSubject(notification: unsent.notification, createLikeMessage: unsent.createLikeMessage, createPostMessage: unsent.createPostMessage) {
                let draft = MessageDraft(to: [account.user], subject: subject, htmlBody: nil, plainTextBody: body, friendlyMailHeaders: headers)
                drafts.append(draft)
            }
        }
        
        return (error: nil, messageStore: messages, drafts: drafts)
    }
    
    private static func newCommentNotificationWithMessages(for newCommentNotifications: [NewCommentNotification], messages: MessageStore) -> [NewCommentNotificationWithMessages] {
        var fsck = [(notification: NewCommentNotification, createCommentMessage: CreateCommentMessage, createPostMessage: CreatePostingMessage)]()
        
        for notification in newCommentNotifications {
            if
                let createMessage = messages.getMessage(for: notification.createCommentMessageID) as? CreateCommentMessage,
                let createPostMessage = messages.getMessage(for: createMessage.comment.parentItemMessageID) as? CreatePostingMessage
            {
                let pair = (notification: notification, createCommentMessage: createMessage, createPostMessage: createPostMessage)
                fsck.append(pair)
            }
        }
        
        return fsck
    }

    /*
     Return new comment notifications that should be sent
     to me.
     */
    static func unsentNewCommentNotifications(messages: MessageStore) -> Set<NewCommentNotification> {
        /*
         1. Get all CreateCommentMessages.
         2. Filter based on creator (not me).
         3. Filter based on creator of post.
         3. Get all new comment notifications.
         */
        
        let account = messages.account!
        
        let createCommentMessages: [CreateCommentMessage] = messages.allMessages.compactMap {
            if
                let fm = $0 as? CreateCommentMessage,
                fm.header.sender != account.user,
                let parentItemMessage = messages.getMessage(for: fm.comment.parentItemMessageID) as? CreatePostingMessage,
                parentItemMessage.header.fromAddress == account.user
            {
                return fm
            }
            return nil
        }
        
        let notifications = createCommentMessages.compactMap {
            return NewCommentNotification(createCommentMessageID: $0.header.messageID)
        }
        
        let sentNotifications: [NewCommentNotification] = messages.allMessages.compactMap {
            if
                let fm = $0 as? NotificationsMessage,
                fm.header.toAddress.first == account.user
            {
                return fm.notifications.compactMap { notification in
                    return notification as? NewCommentNotification
                }
            }
            return []
        }.reduce([], +)
        
        let unsentNewCommentNotifications = Set(notifications).subtracting(Set(sentNotifications))
        return unsentNewCommentNotifications
    }
    
    private static func sentNewCommentNotifications(account: FriendlyMailAccount, messages: MessageStore) -> Set<NewCommentNotification> {
        let sentNotifications: [NewCommentNotification] = messages.allMessages.compactMap {
            if
                let fm = $0 as? NotificationsMessage,
                fm.header.toAddress.first == account.user
            {
                return fm.notifications.compactMap { notification in
                    return notification as? NewCommentNotification
                }
            }
            return []
        }.reduce([], +)
        
        return Set(sentNotifications)
    }
    
    private static func sentNewLikeNotifications(account: FriendlyMailAccount, messages: MessageStore) -> Set<NewLikeNotification> {
        let sentNotifications: [NewLikeNotification] = messages.allMessages.compactMap {
            if
                let fm = $0 as? NotificationsMessage,
                fm.header.toAddress.first == account.user
            {
                return fm.notifications.compactMap { notification in
                    return notification as? NewLikeNotification
                }
            }
            return []
        }.reduce([], +)
        
        return Set(sentNotifications)
    }
    
    static func newLikeNotificationWithMessages(for newLikeNotifications: [NewLikeNotification], messages: MessageStore) -> [NewLikeNotificationWithMessages] {
        var fsck = [NewLikeNotificationWithMessages]()
        
        for notification in newLikeNotifications {
            if
                let createMessage = messages.getMessage(for: notification.createLikeMessageID) as? CreateLikeMessage,
                let createPostMessage = messages.getMessage(for: createMessage.like.parentItemMessageID) as? CreatePostingMessage
            {
                let pair = (notification: notification, createLikeMessage: createMessage, createPostMessage: createPostMessage)
                fsck.append(pair)
            }
        }
        
        return fsck
    }
    
    /*
     Return new like notifications that should be sent
     to me.
     */
    static func unsentNewLikeNotifications(messages: MessageStore) -> Set<NewLikeNotification> {
        /*
         1. Get all CreateLikeMessages.
         2. Filter based on creator (not me).
         3. Filter based on creator of post.
         3. Get all new like notifications.
         */
        
        let account = messages.account!
        
        let createLikeMessages: [CreateLikeMessage] = messages.allMessages.compactMap {
            if
                let fm = $0 as? CreateLikeMessage,
                fm.header.sender != account.user,
                let parentItemMessage = messages.getMessage(for: fm.like.parentItemMessageID) as? CreatePostingMessage,
                parentItemMessage.header.fromAddress == account.user
            {
                return fm
            }
            return nil
        }
        
        let notifications = createLikeMessages.compactMap {
            return NewLikeNotification(createLikeMessageID: $0.header.messageID)
        }
        
        let sentNotifications = MailController.sentNewLikeNotifications(account: account, messages: messages)
        
        let unsentNewLikeNotifications = Set(notifications).subtracting(Set(sentNotifications))
        
        return unsentNewLikeNotifications
    }
    
    /*
     Return new post notifications that should be sent
     to a given follower.
     */
    static func unsentNewPostNotifications(messages: MessageStore, for subscription: Subscription) -> [NewPostNotificationWithMessage] {
        let account = messages.account!
        
        switch subscription.frequency {
            /*
             If realtime, send any unsent for between now and last sent.
             */
        case .realtime:
            /*
             1. Find most recent sent new post notifications.
             2. Calculate all that should be sent for between then and now.
             */
            let notificationsMessagesWithNewPostNotificationsForSubscription: [NotificationsMessage] = messages.allMessages.compactMap {
                if
                    let fm = $0 as? NotificationsMessage,
                    fm.header.toAddress.first == subscription.follower
                {
                    let firstNewPostNotification = fm.notifications.first { notification in
                        notification is NewPostNotification
                    }
                    if let _ = firstNewPostNotification {
                        return fm
                    }
                }
                return nil
            }
            
            let sortedSent = notificationsMessagesWithNewPostNotificationsForSubscription.sorted { first, second in
                return first.header.date > second.header.date
            }
            
            let now = Date()
            
            let startDate: Date = {
                if
                    let mostRecentSent = sortedSent.first,
                    let plusASec = Calendar.current.date(byAdding: .second, value: 1, to: mostRecentSent.header.date)
                {
                    return plusASec
                } else {
                    return now - Date.timeIntervalSinceReferenceDate
                }
            }()
            
            let newPostNotificationsToSend = MailController.newPostNotifications(messages: messages, for: subscription, start: startDate, end: now)
                        
            let notificationsWithPosts: [NewPostNotificationWithMessage] = newPostNotificationsToSend.compactMap {
                if let message = messages.getMessage(for: $0.createPostMessageID) as? CreatePostingMessage {
                    return (notification: $0, createPostMessage: message)
                }
                return nil
            }
            
            return notificationsWithPosts
        case .daily, .weekly, .monthly:
            break
        }
        
        return [NewPostNotificationWithMessage]()
    }
    
    /*
     Return new post notifications that have been sent to a given
     follower.
     */
    static func sentNewPostNotifications(settings: Settings, messages: MessageStore, for subscription: Subscription) -> [NewPostNotification] {
        let notificationsMessagesForSubscription: [NotificationsMessage] = messages.allMessages.compactMap {
            if
                let fm = $0 as? NotificationsMessage,
                let recipient = fm.header.toAddress.first,
                recipient == subscription.follower
            {
                return fm
            }
            return nil
        }
        
        let sentNotifications = notificationsMessagesForSubscription.compactMap { $0.notifications }.reduce([], +)
        let sentNewPostNotifications = sentNotifications.compactMap { $0 as? NewPostNotification }
        
        return sentNewPostNotifications
    }
    
    /*
     Return all new post notifications for a subscription for posts created
     for a given time period.
     */
    static func newPostNotifications(messages: MessageStore, for subscription: Subscription, start: Date, end: Date) -> [NewPostNotification] {
        let createPostMessagesDuringInterval: [CreatePostingMessage] = messages.allMessages.compactMap {
            if
                let fm = $0 as? CreatePostingMessage,
                fm.header.date > start,
                fm.header.date < end
            {
                return fm
            }
            return nil
        }
        
        let notifications = createPostMessagesDuringInterval.compactMap {
            return NewPostNotification(createPostMessageID: $0.header.messageID)
        }
        
        return notifications
    }
    
    /*
     Return all sent notifications. A sent notification will have a corresponding message.
     */
    static func sentNotifications(for subscription: Subscription) {
        
    }
    
    /*
     Return all invites.
     */
    static func invites(inviter: Address, messages: MessageStore) -> [Invite] {
        let createInvitesMessages = messages.allMessages.compactMap {
            return $0 as? CreateInvitesMessage
        }
        let invites = createInvitesMessages.compactMap { $0.invites }.reduce([], +)
        return invites
    }
    
    /*
     Return all unsent invites. An unsent invite will not have a corresponding InviteMessage.
     */
    static func unsentInvites(inviter: Address, messages: MessageStore) -> [Invite] {
        let invites = Set<Invite>(MailController.invites(inviter: inviter, messages: messages))
        let sentInvites = MailController.sentInvites(inviter: inviter, messages: messages)
        let unsentInvites = invites.subtracting(sentInvites)
        
        return Array(unsentInvites)
    }
    
    /*
     Return all sent invites. A sent invite will have a corresponding InviteMessage.
     */
    static func sentInvites(inviter: Address, messages: MessageStore) -> [Invite] {
        let inviteMessages = messages.allMessages.compactMap {
            return $0 as? InviteMessage
        }
        let inviteMessagesFromInviter = inviteMessages.filter { $0.invite.inviter == inviter }
        let sentInvites = inviteMessagesFromInviter.compactMap { $0.invite }
        
        return sentInvites
    }    
    
    /*
     Return all subscriptions for address.
     */
    static func subscriptions(forAddress address: Address, messages: MessageStore) -> [Subscription] {
        let subscriptions: [Subscription] = messages.allMessages.compactMap {
            if
                let fm = $0 as? CreateSubscriptionMessage,
                fm.subscription.followee == address
            {
                return [fm.subscription]
            }
            else if
                let fm = $0 as? CreateAddFollowersMessage,
                fm.followee == address
            {
                return fm.subscriptions
            }
            return nil
        }.reduce([], +)

        return subscriptions
    }
    
    /*
     Return all followers and following for address.
     */
    public static func followersFollowing(forAddress address: Address, messages: MessageStore) -> (followers: [Address], following: [Address]) {
        var followers = [Address]()
        var following = [Address]()

        messages.allMessages.forEach {
            if let fm = $0 as? CreateSubscriptionMessage {
                if fm.subscription.followee == address {
                    followers.append(fm.subscription.follower)
                } else if fm.subscription.follower == address {
                    following.append(fm.subscription.followee)
                }
            }
            else if
                let fm = $0 as? CreateAddFollowersMessage,
                fm.followee == address
            {
                fm.subscriptions.forEach { followers.append($0.follower) }
            }
        }

        return (followers, following)
    }
    
    /*
     Return all commands.
     */
    static func commands(messages: MessageStore, host: Address) -> [Command] {
        let createCommandsMessages = messages.allMessages.compactMap {
            return $0 as? CreateCommandsMessage
        }
        let createCommandsMessagesToHost = createCommandsMessages.filter { $0.header.toAddress.contains(host) }
        let commands = createCommandsMessagesToHost.compactMap { $0.commands }.reduce([], +)
        return commands
    }
    
    /*
     Return all unhandled commands. An unhandled command will not have a corresponding CommandResultMessage.
     */
    static func unhandledCommands(messages: MessageStore, host: Address) -> [Command] {
        let commands = Set<Command>(MailController.commands(messages: messages, host: host))
        let handledCommands = MailController.handledCommands(messages: messages, host: host)

        let unhandledCommands = commands.filter { command in
            handledCommands.contains(command) == false
        }
        
        return Array(unhandledCommands)
    }
    
    /*
     Return all handled commands. A handled command will have a corresponding CommandResultMessage.
     */
    static func handledCommands(messages: MessageStore, host: Address) -> [Command] {
        let commandResultMessages = messages.allMessages.compactMap {
            return $0 as? AnyCommandResultMessage
        }
        
        let commandResultMessagesForAccountUser = commandResultMessages.filter { $0.header.fromAddress == host }
        
        let handledCommands: [Command] = commandResultMessagesForAccountUser.compactMap { $0.commandResult.command }
        return handledCommands
    }
    
    static func handle(createCommandsMessage: CreateCommandsMessage, command: Command, messages: MessageStore, host: Address) -> CommandResult {
        switch command.commandType {
        case .createAccount:
            return CommandController.handleCreateAccount(createCommandsMessage: createCommandsMessage, command: command, messages: messages, host: host)
        case .createInvites, .unknown, .setProfilePic:
            let message = "command not found"
            
            let result = CommandResult(createCommandMessageID: command.createCommandsMessageID,
                                       commandType: command.commandType,
                                       command: command,
                                       user: createCommandsMessage.header.fromAddress,
                                       message: message,
                                       exitCode: .fail)
            return result
        }
    }
    
}