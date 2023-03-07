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
    public var commandResultsMessages: [any AnyCommandResultsMessage] {
        get {
            return allMessages.compactMap { $0 as? (any AnyCommandResultsMessage) }
        }
    }
    
    public var setProfilePicSucceededCommandResults: [SetProfilePicSucceededCommandResult] {
        typealias DateCommandResult = (date: Date, commandResult: any AnyCommandResult)
        
        let commandResults: [DateCommandResult] = commandResultsMessages.map { message in
            message.commandResults.compactMap { result in
                if result.user == account!.user && result is SetProfilePicSucceededCommandResult {
                    return DateCommandResult(date: message.header.date, commandResult: result)
                }
                return nil
            }
        }.reduce([], +)
        
        let sorted = commandResults.sorted(using: KeyPathComparator(\.date, order: .forward))
        return sorted.compactMap { $0.commandResult as?  SetProfilePicSucceededCommandResult }
    }

    public var addFollowersSucceededCommandResults: [AddFollowersSucceededCommandResult] {
        typealias DateCommandResult = (date: Date, commandResult: any AnyCommandResult)
        
        let commandResults: [DateCommandResult] = commandResultsMessages.map { message in
            message.commandResults.compactMap { result in
                if result.user == account!.user && result is AddFollowersSucceededCommandResult {
                    return DateCommandResult(date: message.header.date, commandResult: result)
                }
                return nil
            }
        }.reduce([], +)
        
        let sorted = commandResults.sorted(using: KeyPathComparator(\.date, order: .forward))
        return sorted.compactMap { $0.commandResult as?  AddFollowersSucceededCommandResult }
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
    
    func getCommandResultsMessage(for commandResult: any AnyCommandResult) -> (any AnyCommandResultsMessage)? {
        //return commandResultsMessages.first(where: { $0.commandResults.contains(where: commandResult) } )
        return commandResultsMessages.first
    }
}
