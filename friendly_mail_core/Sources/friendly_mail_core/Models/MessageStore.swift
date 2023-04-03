//
//  MessageStore.swift
//  friendly-mail
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
    public var account: FriendlyMailAccount? {
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
/*
        typealias DateCommandResult = (date: Date, commandResult: CommandResult)
        
        var commandResults = [DateCommandResult]()
        
        commandResultsMessages.forEach { message in
            message.commandResults.forEach { result in
                if result is T {
                    let pair: DateCommandResult = (date: message.header.date, commandResult: result)
                    commandResults.append(pair)
                }
            }
        }
        
        let sorted = commandResults.sorted(using: KeyPathComparator(\.date, order: .forward))
        return sorted.compactMap { $0.commandResult as? T }
 */
    }
    
    public func commandResults<T: CommandResult>(ofType: T.Type, user: Address? = nil, host: Address? = nil) -> [T] {
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
    
    public func postings(author: Address, from: Date? = nil, to: Date? = nil) -> [SocialMediaPosting] {
        let createPostingMessages = messages(ofType: CreatePostingMessage.self)
        
        let range = (from ?? Date.distantPast)...(to ?? Date.distantFuture)
        
        let postings = createPostingMessages.compactMap {
            if
                $0.posting.author.id == author.id,
                range.contains($0.posting.dateCreated)
            {
                return $0.posting
            }
            return nil
        }
        
        return postings
    }
    
    public func notifications(follow: Follow, from: Date? = nil, to: Date? = nil) -> [Notification] {
        let notificationsMessages = messages(ofType: NotificationsMessage.self)
        
        let notifications: [Notification] = notificationsMessages.compactMap { message in
            return message.notifications.filter { $0.follow == follow }
        }.reduce([], +)
    
        return notifications
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
    
    func getCreatePostingMessage(for posting: SocialMediaPosting) -> (CreatePostingMessage)? {
        return messages(ofType: CreatePostingMessage.self).first(where: { $0.posting == posting } )
    }
}
