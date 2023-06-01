//
//  MessageStore.swift
//  friendlymail
//
//  Created by Philip Loden on 1/18/22.
//

import Foundation

public struct MessageStore {
    private let messages: [MessageID : any AnyBaseMessage]
    var numMessages: Int {
        get {
            return messages.count
        }
    }
    public var allMessages: [any AnyBaseMessage] {
        get {
            return Array(messages.values)
        }
    }
    public var hostUser: FriendlyMailUser? {
        let message = allMessages.first { message in
            return (message as? CommandResultsMessage)?.commandResults.contains(where: { $0 is CreateAccountSucceededCommandResult } ) ?? false
        }
        
        if
            let result = (message as? CommandResultsMessage)?.commandResults.first(where: { $0 is CreateAccountSucceededCommandResult } ),
            let createAccountSucceededCommandResult = result as? CreateAccountSucceededCommandResult
        {
            return createAccountSucceededCommandResult.account
        }
        return nil
    }
    public var preferences: Preferences? {
        return Preferences(selectedThemeID: "")
    }
    public var commandResultsMessages: [CommandResultsMessage] {
        get {
            return allMessages.compactMap { $0 as? (CommandResultsMessage) }
        }
    }

    public func messages<T: AnyBaseMessage>(ofType: T.Type) -> [T] {
        return allMessages.compactMap { $0 is T ? $0 as? T : nil }
    }
    
    public func commandResults<T: CommandResult>(ofType: T.Type = CommandResult.self, user: EmailAddress? = nil, host: EmailAddress? = nil) -> [T] {
        typealias DateCommandResult = (date: Date, commandResult: CommandResult)
        
        var commandResults = [DateCommandResult]()
        
        commandResultsMessages.forEach { message in
            message.commandResults.forEach { result in
                if
                    let host = host,
                    let user = user
                {
                    if result is T && result.host.id == host.id && result.user.id == user.id  {
                        let pair: DateCommandResult = (date: message.header.date, commandResult: result)
                        commandResults.append(pair)
                    }
                } else if let host = host {
                    if result is T && result.host.id == host.id {
                        let pair: DateCommandResult = (date: message.header.date, commandResult: result)
                        commandResults.append(pair)
                    }
                } else if let user = user {
                    if result is T && result.user.id == user.id {
                        let pair: DateCommandResult = (date: message.header.date, commandResult: result)
                        commandResults.append(pair)
                    }
                } else {
                    if result is T {
                        let pair: DateCommandResult = (date: message.header.date, commandResult: result)
                        commandResults.append(pair)
                    }
                }
            }
        }
        
        let sorted = commandResults.sorted(using: KeyPathComparator(\.date, order: .forward))
        return sorted.compactMap { $0.commandResult as? T }
    }
    
    public func postings(for authorID: PersonID, from: Date? = nil, to: Date? = nil) -> [SocialMediaPosting] {
        let createPostingMessages = messages(ofType: CreatePostingMessage.self)
        
        let range = (from ?? Date.distantPast)...(to ?? Date.distantFuture)
        
        let postings = createPostingMessages.compactMap {
            if
                $0.posting.author.id == authorID,
                range.contains($0.posting.dateCreated)
            {
                return $0.posting
            }
            return nil
        }   
        
        return postings
    }
    
    public func comments(forPosting posting: SocialMediaPosting? = nil, forAuthor authorID: PersonID? = nil, from: Date? = nil, to: Date? = nil) -> [Comment] {
        guard posting != nil || authorID != nil else {
            return []
        }
        
        let createCommentMessages = messages(ofType: CreateCommentMessage.self)
        
        let range = (from ?? Date.distantPast)...(to ?? Date.distantFuture)
        
        let comments = createCommentMessages.compactMap {
            if
                let posting = posting,
                let author = authorID,
                $0.comment.parentItemID == posting.id,
                $0.posting.author.id == author,
                range.contains($0.posting.dateCreated)
            {
                return $0.comment
            }
            if
                $0.posting.author.id == authorID,
                range.contains($0.posting.dateCreated)
            {
                return $0.comment
            }
            return nil
        }
        
        return comments
    }
    
    /// Return all notifications that have been sent for a given follow.
    public func notifications<T: Notification>(ofType: T.Type = Notification.self, follow: UserFollow, from: Date? = nil, to: Date? = nil) -> [T] {
        typealias DateNotification = (date: Date, notification: Notification)
        
        var notifications = [DateNotification]()
        
        messages(ofType: NotificationsMessage.self).forEach { message in
            message.notifications.forEach { result in
                if result is T && result.follow.id == follow.id {
                    let pair: DateNotification = (date: message.header.date, notification: result)
                    notifications.append(pair)
                }
            }
        }
        
        let sorted = notifications.sorted(using: KeyPathComparator(\.date, order: .forward))
        return sorted.compactMap { $0.notification as? T }
    }
    
    /// Return all commands sent to a specified host.
    public func commands(messages: MessageStore, host: EmailAddress) -> [Command] {
        let createCommandsMessages = messages.allMessages.compactMap {
            return $0 as? CreateCommandsMessage
        }
        let createCommandsMessagesToHost = createCommandsMessages.filter { $0.header.toAddress.containsIdentifiable(host) }
        let commands = createCommandsMessagesToHost.compactMap { $0.commands }.reduce([], +)
        return commands
    }
    
    /// Return all follows for a given followee ID or follower ID.
    ///
    /// Results include both UserFollows and PostingFollows.
    public func follows(followee followeeID: PersonID, from: Date? = Date.distantPast, to: Date? = Date.distantFuture) -> [UserFollow] {
        let follows: [UserFollow] = commandResults(ofType: AddFollowersSucceededCommandResult.self).compactMap { result in
            if result.followee == followeeID {
                return result.follows
            }
            return nil
        }.reduce([], +)
        return follows
    }
        
    /// Return all commands that a given host has handled. A handled command will have a corresponding CommandResultMessage.
    public func handledCommands(host: EmailAddress) -> [Command] {
        let handledCommandResults = commandResults(ofType: CommandResult.self, host: host)
        let handledCommands = handledCommandResults.compactMap { $0.command }
        return handledCommands
    }
    
    /// Return all invites.
    public func invites(inviter: EmailAddress) -> [Invite] {
        let createInvitesMessages = allMessages.compactMap {
            return $0 as? CreateInvitesMessage
        }
        let invites = createInvitesMessages.compactMap { $0.invites }.reduce([], +)
        return invites
    }
    
    public init() {
        messages = [MessageID : any AnyBaseMessage]()
    }
    
    public init(messages: [MessageID : any AnyBaseMessage]) {
        self.messages = messages
    }
    
    func addingMessage(message: any AnyBaseMessage, messageID: MessageID) -> MessageStore {
        let messageToAdd: [MessageID : any AnyBaseMessage] = [messageID: message]
        return merging(messages: messageToAdd)
    }
    
    public func merging(messageStore: MessageStore) -> MessageStore {
        return merging(messages: messageStore.messages)
    }
    
    public func merging(messages: [MessageID : any AnyBaseMessage]) -> MessageStore {
        let mergedMessages = self.messages.merging(messages) { (old, new) in
            return old.merging(message: new)
        }
        return MessageStore(messages: mergedMessages)
    }
    
    func getMessage(for messageID: MessageID) -> (any AnyBaseMessage)? {
        return messages[messageID]
    }
    
    func getMessages(for messageIDs: [MessageID]) -> [any AnyBaseMessage] {
        return messageIDs.compactMap { getMessage(for: $0) }
    }
    
    func getCommandResultsMessage(for commandResult: CommandResult) -> (CommandResultsMessage)? {
        return commandResultsMessages.first(where: { $0.commandResults.contains(commandResult) } )
    }
    
    func getNotificationsMessage(for notification: Notification) -> (NotificationsMessage)? {
        return messages(ofType: NotificationsMessage.self).first(where: { $0.notifications.contains(notification) } )
    }
    
    func getCreatePostingMessage(for posting: SocialMediaPosting) -> (CreatePostingMessage)? {
        return messages(ofType: CreatePostingMessage.self).first(where: { $0.posting == posting } )
    }
    
    func getCreateCommentMessage(for comment: Comment) -> (CreateCommentMessage)? {
        return messages(ofType: CreateCommentMessage.self).first(where: { $0.comment == comment } )
    }
    
    func getEmailAddress(for personID: PersonID) -> EmailAddress? {
        return EmailAddress(address: personID)
    }
    
    /*
    func getUser(for personID: PersonID) -> Person? {
        if hostUser?.id == personID {
            return hostUser
        } else {
            let postings = postings(for: personID)
        }
        return nil
    }
     */
}
