//
//  MailController.swift
//  friendlymail
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

public class MailController {
    
    public static func getAndProcessAndSendMail(config: AppConfig,
                                                sender: MessageSender,
                                                receiver: MessageReceiver,
                                                messages: MessageStore,
                                                storageProvider: StorageProvider,
                                                logger: Logger? = nil,
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
                        logger?.log(message: "MailController: getAndProcessAndSendMail: starting sendMessage with subject \"\(draft.subject)\"")
                        sender.sendMessage(to: draft.to, subject: draft.subject, htmlBody: draft.htmlBody, plainTextBody: draft.plainTextBody, friendlyMailHeaders: draft.friendlyMailHeaders, logger: logger) { sendMessageResult in
                            if let _ = try? sendMessageResult.get() {
                                sentCount += 1
                                logger?.log(message: "MailController: getAndProcessAndSendMail: sendMessage completed")
                            } else {
                                logger?.log(message: "MailController: getAndProcessAndSendMail: sendMessage failed")
                            }
                            
                            if
                                let hostUser = updatedMessages.hostUser,
                                let sentMessageID = try? sendMessageResult.get(),
                                draft.to.containsIdentifiable(hostUser)
                            {
                                toMoveToInbox.append(sentMessageID)
                            }
                            outerError = error ?? outerError
                            downloadGroup.leave()
                        }
                    }
                    downloadGroup.wait()
                    
                    logger?.log(message: "MailController: getAndProcessAndSendMail: sent \(sentCount) messages.")
                    
                    var movedCount = 0
                    
                    for toMoveMessageID in toMoveToInbox {
                        downloadGroup.enter()
                        
                        logger?.log(message: "MailController: getAndProcessAndSendMail: starting fetchFriendlyMailMessage")
                        receiver.fetchFriendlyMailMessage(messageID: toMoveMessageID) { fetchError, fetchedMessage in
                            if let _ = fetchError {
                                logger?.log(message: "MailController: getAndProcessAndSendMail: fetchFriendlyMailMessage failed")
                            } else {
                                logger?.log(message: "MailController: getAndProcessAndSendMail: fetchFriendlyMailMessage succeeded")
                                if let fetchedMessage = fetchedMessage {
                                    downloadGroup.enter()
                                    logger?.log(message: "MailController: getAndProcessAndSendMail: fetchFriendlyMailMessage: starting moveMessageToInbox")
                                    sender.moveMessageToInbox(message: fetchedMessage) { moveError in
                                        logger?.log(message: "MailController: getAndProcessAndSendMail: fetchFriendlyMailMessage: moveMessageToInbox finished")
                                        movedCount += moveError == nil ? 1 : 0
                                        downloadGroup.leave()
                                    }
                                }
                            }
                            downloadGroup.leave()
                        }
                    }
                    logger?.log(message: "MailController: getAndProcessAndSendMail: moved \(sentCount) messages.")
                    
                    downloadGroup.enter() // for get mail
                    logger?.log(message: "MailController: getAndProcessAndSendMail: starting downloadFriendlyMailMessages")
                    receiver.downloadFriendlyMailMessages() { error, messages in
                        logger?.log(message: "MailController: getAndProcessAndSendMail: downloadFriendlyMailMessages completed")
                        outerError = error ?? outerError
                        if let messages = messages {
                            updatedMessages = updatedMessages.merging(messageStore: messages)
                        }
                        downloadGroup.leave()
                    }
                    
                    downloadGroup.notify(queue: DispatchQueue.main) {
                        let shouldFetch = updatedMessages.allMessages.filter { $0.shouldFetch }
                        logger?.log(message: "MailController: getAndProcessAndSendMail: shouldFetch count before completion: \(shouldFetch.count)")
                        logger?.log(message: "MailController: getAndProcessAndSendMail completed")
                        completion(outerError, updatedMessages)
                    }
                }
            }
        }
    }
    
    static func getAndProcessMail(config: AppConfig, sender: MessageSender, receiver: MessageReceiver, messages: MessageStore, storageProvider: StorageProvider, logger: Logger?, completion: @escaping (Error?, MessageStore, [MessageDraftProtocol]) -> ()) {
        // first get sent mail, or we might send duplicates. Or do we? Sent messages are tagged friendlymail.
        
        // fetch messages with nil bodies
        
        var updatedMessages = messages
                
        DispatchQueue.global(qos: .default).async {
            receiver.downloadFriendlyMailMessages() { error, messages in
                if let messages = messages, error == nil {
                    let previousCount = updatedMessages.numMessages
                    updatedMessages = updatedMessages.merging(messageStore: messages)
                    let currentCount = updatedMessages.numMessages
                    logger?.log(message: "MailController: getAndProcessMail: downloadFriendlyMailMessages: downloaded \(currentCount - previousCount) messages.")
                    
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
                                logger?.log(message: "MailController: getAndProcessMail: fetchMessage: downloaded \(type(of: fetchedMessage)) message.")
                            } else if let fetchError = fetchError {
                                logger?.log(message: "MailController: getAndProcessMail: fetchMessage: error fetching message with uid: \(message.uidWithMailbox.UID). error: \(fetchError.localizedDescription)")
                            }
                            downloadGroup.leave()
                        }
                    }
                    
                    downloadGroup.leave()
                    
                    downloadGroup.notify(queue: DispatchQueue.main) {
                        logger?.log(message: "MailController: getAndProcessMail: fetched \(fetchCount) messages.")

                        let finalMessages = updatedMessages

                        let shouldFetch = finalMessages.allMessages.filter { $0.shouldFetch }
                        logger?.log(message: "MailController: getAndProcessMail: shouldFetch count after fetch: \(shouldFetch.count)")

                        Task.init {
                            let hostUserBefore = finalMessages.hostUser

                            var errorMessagesDrafts = await processMail(config: config, sender: sender, receiver: receiver, messages: finalMessages, storageProvider: storageProvider)
                            
                            let hostUserAfter = errorMessagesDrafts.messageStore.hostUser
                            
                            if hostUserBefore != hostUserAfter {
                                // re-instantiate messages with new account. need to do after process mail, and then re-process
                                var keysMessages = [MessageID:any BaseMessageProtocol]()
                                errorMessagesDrafts.messageStore.allMessages.forEach { message in
                                    if let updated = MessageFactory.createMessage(account: errorMessagesDrafts.messageStore.hostUser,
                                                                                  uidWithMailbox: message.uidWithMailbox,
                                                                                  header: message.header,
                                                                                  htmlBody: message.htmlBody,
                                                                                  friendlyMailData: nil,
                                                                                  plainTextBody: message.plainTextBody,
                                                                                  attachments: message.attachments,
                                                                                  logger: logger)
                                    {
                                        keysMessages[updated.id] = updated
                                    }
                                }
                                errorMessagesDrafts.messageStore = errorMessagesDrafts.messageStore.merging(messages: keysMessages)
                                errorMessagesDrafts = await processMail(config: config, sender: sender, receiver: receiver, messages: errorMessagesDrafts.messageStore, storageProvider: storageProvider)
                                completion(errorMessagesDrafts.error, errorMessagesDrafts.messageStore, errorMessagesDrafts.drafts)
                            } else {
                                completion(errorMessagesDrafts.error, errorMessagesDrafts.messageStore, errorMessagesDrafts.drafts)
                            }
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
    static func processMail(config: AppConfig, sender: MessageSender, receiver: MessageReceiver, messages: MessageStore, storageProvider: StorageProvider, logger: Logger? = nil) async -> (error: Error?, messageStore: MessageStore, drafts: [MessageDraftProtocol]) {
        var drafts = [MessageDraftProtocol]()
        
        let hostUser = messages.hostUser
        let prefs = messages.preferences!
        let theme = config.themes.first { $0.id == prefs.selectedThemeID } ?? config.defaultTheme
        
        // handle commands
        let host = hostUser?.email ?? receiver.address
        let unhandledCommands = MailController.unhandledCommands(messages: messages, host: host)
        
        let commandResultMessageDrafts = await CommandController.handle(commands: unhandledCommands, messages: messages, host: host, storageProvider: storageProvider, theme: theme)
        drafts += commandResultMessageDrafts
        
        // can only proceed if we have an account
        guard let hostUser = hostUser else {
            return (error: nil, messageStore: messages, drafts: drafts)
        }
        
        /*
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
         */
        
        // send notifications to followers
        let follows = messages.follows(followee: hostUser.id)
        
        var unsentNewPostNotificationsCount = 0
        let draftsCountWithoutNotificationMessages = drafts.count
        
        for follow in follows {
            let unsentNewPostNotifications = MailController.unsentNewPostNotifications(messages: messages, for: follow )
            unsentNewPostNotificationsCount += unsentNewPostNotifications.count
            
            drafts += unsentNewPostNotifications.compactMap {
                if let followerAddress = messages.getEmailAddress(for: follow.followerID) {
                    return NotificationsMessageDraft(to: [followerAddress],
                                                     notifications: [$0],
                                                     theme: theme,
                                                     messages: messages)
                }
                return nil
            }
            
            let unsentNewCommentNotifications = MailController.unsentNewCommentNotifications(messages: messages, for: follow)
            
            drafts += unsentNewCommentNotifications.compactMap {
                if let followerAddress = messages.getEmailAddress(for: follow.followerID) {
                    return NotificationsMessageDraft(to: [followerAddress],
                                                     notifications: [$0],
                                                     theme: theme,
                                                     messages: messages)!
                }
                return nil
            }
            
            let unsentNewLikeNotifications = MailController.unsentNewLikeNotifications(messages: messages, for: follow)
            
            drafts += unsentNewLikeNotifications.compactMap {
                if let followerAddress = messages.getEmailAddress(for: follow.followerID) {
                    return NotificationsMessageDraft(to: [followerAddress],
                                                     notifications: [$0],
                                                     theme: theme,
                                                     messages: messages)
                }
                return nil
            }
        }
        
        let draftsCountWithNotificationMessages = drafts.count
        let notificationsMessageDraftsCount = draftsCountWithNotificationMessages - draftsCountWithoutNotificationMessages
        
        let followersString = follows.map { $0.followerID }.joined(separator: " ")
        logger?.log(message: "MailController: processMail: followers: \(follows.count) [\(followersString)] unsentNewPostNotifications: \(unsentNewPostNotificationsCount) notificationsMessageDraftsCount: \(notificationsMessageDraftsCount)", level: .debug)
        
        return (error: nil, messageStore: messages, drafts: drafts)
    }

    /*
     Return new comment notifications that should be sent. Notifications are sent
     to the author of the posting being commented on (me).
     */
    static func unsentNewCommentNotifications(messages: MessageStore, for follow: UserFollow) -> [NewCommentNotification] {
        /*
         1. Find most recent sent new post notifications.
         2. Calculate all that should be sent for between then and now.
         */
        let notificationsMessagesWithNewCommentNotificationsForFollow: [NotificationsMessage] = messages.allMessages.compactMap {
            if
                let fm = $0 as? NotificationsMessage,
                fm.header.toAddress.first?.id == follow.followerID
            {
                let firstNewCommentNotification = fm.notifications.first { notification in
                    notification is NewCommentNotification
                }
                if let _ = firstNewCommentNotification {
                    return fm
                }
            }
            return nil
        }
        
        let sortedSent = notificationsMessagesWithNewCommentNotificationsForFollow.sorted { first, second in
            return first.header.date > second.header.date
        }
        
        let startDate: Date = {
            if
                let mostRecentSent = sortedSent.first,
                let plusANanosec = Calendar.current.date(byAdding: .nanosecond, value: 1, to: mostRecentSent.header.date)
            {
                return plusANanosec
            } else {
                return Date.distantPast
            }
        }()
        
        let comments = messages.comments(forAuthor: messages.hostUser?.id, from: startDate)
        
        let notificationsToSend: [NewCommentNotification] = comments.compactMap {
            if let createCommentMessage = messages.getCreateCommentMessage(for: $0) {
                let notification = NewCommentNotification(follow: follow, createCommentMessageID: createCommentMessage.id)
                return notification
            }
            return nil
        }
        
        return notificationsToSend
    }
    
    /*
     Return new like notifications that should be sent. Notifications are sent
     to the author of the posting being liked (me).
     */
    static func unsentNewLikeNotifications(messages: MessageStore, for follow: UserFollow) -> Set<NewLikeNotification> {
        /*
         1. Get all CreateLikeMessages.
         2. Filter based on creator (not me).
         3. Filter based on creator of post.
         3. Get all new like notifications.
         */
        
        let hostUser = messages.hostUser!
        
        let createLikeMessages: [CreateLikeMessage] = messages.allMessages.compactMap {
            if
                let fm = $0 as? CreateLikeMessage,
                fm.header.fromAddress.id != hostUser.email.id,
                let parentItemMessage = messages.getMessage(for: fm.like.parentItemMessageID) as? CreatePostingMessage,
                parentItemMessage.header.fromAddress.id == hostUser.email.id
            {
                return fm
            }
            return nil
        }
        
        let notifications = createLikeMessages.compactMap {
            return NewLikeNotification(createLikeMessageID: $0.header.messageID)
        }
        
        let sentNotifications = messages.notifications(ofType: NewLikeNotification.self, follow: follow)
        let unsentNewLikeNotifications = Set(notifications).subtracting(Set(sentNotifications))
        
        return unsentNewLikeNotifications
    }
    
    /*
     Return new post notifications that should be sent
     to a given follower.
     */
    static func unsentNewPostNotifications(messages: MessageStore, for follow: UserFollow) -> [NewPostingNotification] {
        /*
         1. Find most recent sent new post notifications.
         2. Calculate all that should be sent for between then and now.
         */
        let notificationsMessagesWithNewPostNotificationsForFollow: [NotificationsMessage] = messages.allMessages.compactMap {
            if
                let fm = $0 as? NotificationsMessage,
                fm.header.toAddress.first?.id == follow.followerID
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
                
        let startDate: Date = {
            if
                let mostRecentSent = sortedSent.first,
                let plusANanosec = Calendar.current.date(byAdding: .nanosecond, value: 1, to: mostRecentSent.header.date)
            {
                return plusANanosec
            } else {
                return Date.distantPast
            }
        }()
        
        let postings = messages.postings(for: messages.hostUser!.id, from: startDate)
        
        let notificationsToSend: [NewPostingNotification] = postings.compactMap {
            if let message = messages.getCreatePostingMessage(for: $0) {
                let notification = NewPostingNotification(follow: follow, createPostingMessageID: message.header.messageID)
                return notification
            }
            return nil
        }
        
        return notificationsToSend
    }
    
    /*
     Return all unsent invites. An unsent invite will not have a corresponding InviteMessage.
     */
    static func unsentInvites(inviter: EmailAddress, messages: MessageStore) -> [Invite] {
        let invites = Set<Invite>(messages.invites(inviter: inviter))
        let sentInvites = MailController.sentInvites(inviter: inviter, messages: messages)
        let unsentInvites = invites.subtracting(sentInvites)
        
        return Array(unsentInvites)
    }
    
    /*
     Return all sent invites. A sent invite will have a corresponding InviteMessage.
     */
    static func sentInvites(inviter: EmailAddress, messages: MessageStore) -> [Invite] {
        let inviteMessages = messages.allMessages.compactMap {
            return $0 as? InviteMessage
        }
        let inviteMessagesFromInviter = inviteMessages.filter { $0.invite.inviter == inviter }
        let sentInvites = inviteMessagesFromInviter.compactMap { $0.invite }
        
        return sentInvites
    }    
    
    /*
     Return all unhandled commands. An unhandled command will not have a corresponding CommandResultMessage.
     */
    static func unhandledCommands(messages: MessageStore, host: EmailAddress) -> [Command] {
        let commands = Set<Command>(messages.commands(messages: messages, host: host))
        let handledCommands = Set<Command>(messages.handledCommands(host: host))
        let unhandledCommands = commands.subtracting(handledCommands)
        return Array(unhandledCommands)
    }
    
}
