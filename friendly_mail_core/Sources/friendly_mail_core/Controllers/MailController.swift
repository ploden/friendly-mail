//
//  MailController.swift
//  friendly-mail
//
//  Created by Philip Loden on 7/24/21.
//

import Foundation
import Stencil

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
public typealias NewPostNotificationWithMessage = (notification: NewPostingNotification, createPostMessage: CreatePostingMessage)
public typealias NewCommentNotificationWithMessages = (notification: NewCommentNotification, createCommentMessage: CreateCommentMessage, createPostMessage: CreatePostingMessage)

public class MailController {
    
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
                                                storageProvider: StorageProvider,
                                                logger: Logger?,
                                                completion: @escaping (Error?, MessageStore) -> ())
    {
        MailController.getAndProcessMail(config: config, sender: sender, receiver: receiver, messages: messages, storageProvider: storageProvider, logger: logger) { error, messagesAfterGetAndProcessMail, drafts in
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
                        sender.sendMessage(to: draft.to, subject: draft.subject, htmlBody: draft.htmlBody, plainTextBody: draft.plainTextBody, friendlyMailHeaders: draft.friendlyMailHeaders) { sendMessageResult in
                            
                            if let _ = try? sendMessageResult.get() {
                                sentCount += 1
                            }
                            
                            if
                                let account = updatedMessages.account,
                                let sentMessageID = try? sendMessageResult.get(),
                                draft.to.containsIdentifiable(account.user)
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
    
    static func getAndProcessMail(config: AppConfig, sender: MessageSender, receiver: MessageReceiver, messages: MessageStore, storageProvider: StorageProvider, logger: Logger?, completion: @escaping (Error?, MessageStore, [AnyMessageDraft]) -> ()) {
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
                        
                        let finalMessages = updatedMessages

                        Task.init {
                            let errorMessagesDrafts = await processMail(config: config, sender: sender, receiver: receiver, messages: finalMessages, storageProvider: storageProvider)
                            completion(errorMessagesDrafts.error, errorMessagesDrafts.messageStore, errorMessagesDrafts.drafts)
                        }
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
    static func processMail(config: AppConfig, sender: MessageSender, receiver: MessageReceiver, messages: MessageStore, storageProvider: StorageProvider, logger: Logger? = nil) async -> (error: Error?, messageStore: MessageStore, drafts: [AnyMessageDraft]) {
        var drafts = [AnyMessageDraft]()
        
        let account = messages.account
        let prefs = messages.preferences!
        let theme = config.themes.first { $0.id == prefs.selectedThemeID } ?? config.defaultTheme
        
        // handle commands
        let host = account?.user ?? receiver.address
        let unhandledCommands = MailController.unhandledCommands(messages: messages, host: host)
        
        let commandResultMessageDrafts = await MailController.handle(commands: unhandledCommands, messages: messages, host: host, storageProvider: storageProvider, theme: theme)
        drafts += commandResultMessageDrafts
        
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
        let follows = MailController.follows(forAddress: account.user, messages: messages)
        
        var unsentNewPostNotificationsCount = 0
        var notificationsMessageDraftsCount = 0
        
        for follow in follows {
            let unsentNewPostNotifications = MailController.unsentNewPostNotifications(messages: messages, for: follow )
            unsentNewPostNotificationsCount += unsentNewPostNotifications.count
            
            drafts += unsentNewPostNotifications.compactMap {
                notificationsMessageDraftsCount += 1
                return NotificationsMessageDraft(to: [follow.follower],
                                          notifications: [$0],
                                          theme: theme,
                                          messages: messages)
            }
            
            /*
             if unsentNewPostNotifications.count > 0 {
             let template = NewPostNotificationTemplate(theme: theme)
             
             let textForUnsentNewPostNotifications: [String] = unsentNewPostNotifications.compactMap { unsentNewPostNotification in
             return template.populatePlainText(with: unsentNewPostNotification.createPostMessage.post, notification: unsentNewPostNotification.notification, follow: follow)
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
             let subject = template.populateSubject(with: first.createPostMessage.post, notification: first.notification, follow: follow)
             {
             let html = template.populateHTML(with: first.createPostMessage.post, notification: first.notification, follow: follow)
             let draft = MessageDraft(to: [follow.follower], subject: subject, htmlBody: html, plainTextBody: joined, friendlyMailHeaders: headers)
             drafts.append(draft)
             }
             */
        }
        
        let followersString = follows.map { $0.follower.address }.joined(separator: " ")
        logger?.log(message: "MailController: processMail: followers: \(follows.count) [\(followersString)] unsentNewPostNotifications: \(unsentNewPostNotificationsCount) notificationsMessageDraftsCount: \(notificationsMessageDraftsCount)", level: .debug)

        // send new comment notifications to me
        let unsentNewCommentNotifications = MailController.unsentNewCommentNotifications(messages: messages)
        let unsentNewCommentNotificationsWithMessages = MailController.newCommentNotificationWithMessages(for: Array(unsentNewCommentNotifications), messages: messages)
        
        drafts += unsentNewCommentNotificationsWithMessages.compactMap {
            NotificationsMessageDraft(to: [account.user],
                                      notifications: [$0.notification],
                                      theme: theme,
                                      messages: messages)
        }
        
        /*
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
         */
        
        // send new like notifications to me
        let unsentNewLikeNotifications = MailController.unsentNewLikeNotifications(messages: messages)
        let unsentNewLikeNotificationsWithMessages = MailController.newLikeNotificationWithMessages(for: Array(unsentNewLikeNotifications), messages: messages)

        drafts += unsentNewLikeNotificationsWithMessages.compactMap {
            NotificationsMessageDraft(to: [account.user],
                                      notifications: [$0.notification],
                                      theme: theme,
                                      messages: messages)
        }
        
        /*
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
         */
        
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
                fm.header.fromAddress != account.user,
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
                fm.header.fromAddress != account.user,
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
    static func unsentNewPostNotifications(messages: MessageStore, for follow: Follow) -> [NewPostingNotification] {
        switch follow.frequency {
            /*
             If realtime, send any unsent for between now and last sent.
             */
        case .realtime, .undefined:
            /*
             1. Find most recent sent new post notifications.
             2. Calculate all that should be sent for between then and now.
             */
            let notificationsMessagesWithNewPostNotificationsForFollow: [NotificationsMessage] = messages.allMessages.compactMap {
                if
                    let fm = $0 as? NotificationsMessage,
                    fm.header.toAddress.first?.id == follow.follower.id
                {
                    let firstNewPostNotification = fm.notifications.first { notification in
                        notification is NewPostingNotification
                    }
                    if let _ = firstNewPostNotification {
                        return fm
                    }
                }
                return nil
            }
            
            let sortedSent = notificationsMessagesWithNewPostNotificationsForFollow.sorted { first, second in
                return first.header.date > second.header.date
            }
            
            let now = Date()
            
            let startDate: Date = {
                if
                    let mostRecentSent = sortedSent.first,
                    let plusANanosec = Calendar.current.date(byAdding: .nanosecond, value: 1, to: mostRecentSent.header.date)
                {
                    return plusANanosec
                } else {
                    //return now - Date.timeIntervalSinceReferenceDate
                    return Date.distantPast
                }
            }()
            
            let postings = messages.postings(author: messages.account!.user, from: startDate)
            
            let notificationsToSend: [NewPostingNotification] = postings.compactMap {
                if let message = messages.getCreatePostingMessage(for: $0) {
                    let notification = NewPostingNotification(createPostingMessageID: message.header.messageID)
                    return notification
                }
                return nil
            }
            
            return notificationsToSend
            //let newPostNotificationsToSend = MailController.newPostNotifications(messages: messages, for: follow, start: startDate, end: now)
               
            /*
            let notificationsWithPosts: [NewPostNotificationWithMessage] = newPostNotificationsToSend.compactMap {
                if let message = messages.getMessage(for: $0.createPostMessageID) as? CreatePostingMessage {
                    return (notification: $0, createPostMessage: message)
                }
                return nil
            }
             */
            
            return [NewPostingNotification]()
        case .daily, .weekly, .monthly:
            break            
        }
        
        return [NewPostingNotification]()
    }
    
    /*
     Return new post notifications that have been sent to a given
     follower.
     */
    static func sentNewPostNotifications(settings: Settings, messages: MessageStore, for follow: Follow) -> [NewPostingNotification] {
        let notificationsMessagesForFollow: [NotificationsMessage] = messages.allMessages.compactMap {
            if
                let fm = $0 as? NotificationsMessage,
                let recipient = fm.header.toAddress.first,
                recipient.id == follow.follower.id
            {
                return fm
            }
            return nil
        }
        
        let sentNotifications = notificationsMessagesForFollow.compactMap { $0.notifications }.reduce([], +)
        let sentNewPostNotifications = sentNotifications.compactMap { $0 as? NewPostingNotification }
        
        return sentNewPostNotifications
    }
    
    /*
    /*
     Return all new post notifications for a subscription for posts created
     for a given time period.
     */
    static func newPostNotifications(messages: MessageStore, for subscription: Follow, start: Date, end: Date) -> [NewPostNotification] {
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
    */
    
    /*
    /*
     Return all sent notifications. A sent notification will have a corresponding message.
     */
    static func sentNotifications(for subscription: Follow) {
        
    }
     */
    
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
     Return all follows for address.
     */
    static func follows(forAddress address: Address, messages: MessageStore) -> [Follow] {
        let follows: [Follow] = messages.commandResults(ofType: AddFollowersSucceededCommandResult.self).compactMap { result in
            if result.followee.id == address.id {
                return result.follows
            }
            return nil
        }.reduce([], +)
        return follows
    }
    
    /*
     Return all followers and following for address.
     */
    public static func followersFollowing(forAddress address: Address, messages: MessageStore) -> (followers: [Address], following: [Address]) {
        var followers = [Address]()
        var following = [Address]()

        messages.allMessages.forEach {
            if let fm = $0 as? CreateFollowMessage {
                if fm.subscription.followee.id == address.id {
                    followers.append(fm.subscription.follower)
                } else if fm.subscription.follower.id == address.id {
                    following.append(fm.subscription.followee)
                }
            }
            else if
                let fm = $0 as? CreateAddFollowersMessage,
                fm.followee.id == address.id
            {
                fm.follows.forEach { followers.append($0.follower) }
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
        let createCommandsMessagesToHost = createCommandsMessages.filter { $0.header.toAddress.containsIdentifiable(host) }
        let commands = createCommandsMessagesToHost.compactMap { $0.commands }.reduce([], +)
        return commands
    }
    
    /*
     Return all unhandled commands. An unhandled command will not have a corresponding CommandResultMessage.
     */
    static func unhandledCommands(messages: MessageStore, host: Address) -> [Command] {
        let commands = Set<Command>(MailController.commands(messages: messages, host: host))
        let handledCommands = Set<Command>(MailController.handledCommands(messages: messages, host: host))
        let unhandledCommands = commands.subtracting(handledCommands)
        return Array(unhandledCommands)
    }
    
    /*
     Return all commands that this host has handled. A handled command will have a corresponding CommandResultMessage.
     */
    static func handledCommands(messages: MessageStore, host: Address) -> [Command] {
        let handledCommandResults = messages.commandResults(ofType: CommandResult.self, host: host)
        let handledCommands = handledCommandResults.compactMap { $0.command }
        return handledCommands
    }
    
    static func handle(commands: [Command], messages: MessageStore, host: Address, storageProvider: StorageProvider, theme: Theme) async -> [AnyMessageDraft] {
        var drafts = [AnyMessageDraft]()
        
        let to = messages.account?.user ?? host
        
        for command in commands {
            
            if let createCommandsMessage = messages.getMessage(for: command.createCommandsMessageID) as? CreateCommandsMessage {
                
                    switch command.commandType {
                    case .createAccount:
                        let resultDrafts = CommandController.handleCreateAccount(createCommandsMessage: createCommandsMessage, command: command, messages: messages, host: host, theme: theme)
                        drafts += resultDrafts
                    case .setProfilePic:
                        let result = await CommandController.handleSetProfilePic(createCommandsMessage: createCommandsMessage, command: command, messages: messages, storageProvider: storageProvider)
                        let commandResultDraft = CommandResultMessageDraft(to: [to], commandResults: [result], theme: theme)
                        drafts += [commandResultDraft!]
                    case .addFollowers:
                        let result = CommandController.handleAddFollowers(createCommandsMessage: createCommandsMessage, command: command, messages: messages, host: host)
                        let commandResultDraft = CommandResultMessageDraft(to: [to], commandResults: [result], theme: theme)
                        drafts += [commandResultDraft!]
                    case .createInvites, .unknown:
                        let message = "\(command.input): command not found"
                        
                        let result = CommandResult(createCommandMessageID: command.createCommandsMessageID,
                                                   commandType: command.commandType,
                                                   command: command,
                                                   message: message,
                                                   exitCode: .fail)
                        let commandResultDraft = CommandResultMessageDraft(to: [to], commandResults: [result], theme: theme)
                        drafts += [commandResultDraft!]
                    }
                
            }
            
        }
        
        return drafts
    }
    
}
