//
//  CommandController.swift
//  
//
//  Created by Philip Loden on 11/21/22.
//

import Foundation

public struct CommandController {
    
    static func handle(commands: [Command], messages: MessageStore, host: EmailAddress, storageProvider: StorageProvider, theme: Theme) async -> [AnyMessageDraft] {
        var drafts = [AnyMessageDraft]()
        
        let to = messages.hostUser?.email ?? host
        
        for command in commands {
            
            if let createCommandsMessage = messages.getMessage(for: command.createCommandsMessageID) as? CreateCommandsMessage {
                
                    switch command.commandType {
                    case .help:
                        let resultDrafts = HelpCommandController.handleHelp(command: command, messages: messages, host: host, theme: theme)
                        drafts += resultDrafts
                    case .createAccount:
                        let resultDrafts = UseraddCommandController.handleCreateAccount(command: command, messages: messages, host: host, theme: theme)
                        drafts += resultDrafts
                    case .setProfilePic:
                        let result = await UsermodCommandController.handleSetProfilePic(createCommandsMessage: createCommandsMessage, command: command, messages: messages, storageProvider: storageProvider)
                        let commandResultDraft = CommandResultMessageDraft(to: [to], commandResults: [result], theme: theme)
                        drafts += [commandResultDraft!]
                    case .follow:
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
    
    static func handleAddFollowers(createCommandsMessage: CreateCommandsMessage, command: Command, messages: MessageStore, host: EmailAddress) -> CommandResult {
        guard Self.hasPermission(command: command, messages: messages) else {
            return Self.createPermissionDeniedCommandResult(command: command)
        }
        
        let followersToAdd = CommandController.extractFollowersToAdd(plainTextBody: command.input, host: host)
        
        if let result = Self.createAddFollowersSucceededCommandResult(createCommandsMessage: createCommandsMessage, command: command, followersToAdd: followersToAdd) {
            return result
        } else {
            return Self.createUnknownErrorCommandResult(command: command)
        }
    }
    
    static func hasPermission(command: Command, messages: MessageStore) -> Bool {
        if
            let hostUser = messages.hostUser,
            command.user.id == hostUser.id
        {
            return true
        }
        return false
    }
    
    static func createPermissionDeniedCommandResult(command: Command) -> CommandResult {
        let message = "permission denied"
        
        let result = CommandResult(createCommandMessageID: command.createCommandsMessageID,
                                   commandType: command.commandType,
                                   command: command,
                                   message: message,
                                   exitCode: .fail)
        return result
    }
    
    static func createUnknownErrorCommandResult(command: Command) -> CommandResult {
        let message = "an unknown error occurred"
        
        let result = CommandResult(createCommandMessageID: command.createCommandsMessageID,
                                   commandType: command.commandType,
                                   command: command,
                                   message: message,
                                   exitCode: .fail)
        return result
    }
    
    static func createAddFollowersSucceededCommandResult(createCommandsMessage: CreateCommandsMessage, command: Command, followersToAdd: [EmailAddress]) -> AddFollowersSucceededCommandResult? {
        let follows = followersToAdd.map {
            UserFollow(followerID: Person(email: $0).id, followeeID: command.user.id, frequency: .realtime, messageID: createCommandsMessage.header.messageID)
        }
        
        guard follows.count > 0 else {
            return nil
        }
        
        let message = "added follower\(followersToAdd.count > 1 ? "s" : "") \(followersToAdd.compactMap { $0.address }.joined(separator: " "))"
        
        let result = AddFollowersSucceededCommandResult(createCommandMessageID: command.createCommandsMessageID,
                                                        commandType: command.commandType,
                                                        command: command,
                                                        user: createCommandsMessage.header.fromAddress,
                                                        message: message,
                                                        exitCode: .success,
                                                        follows: follows)
        return result
    }
    
    static func extractFollowersToAdd(plainTextBody: String, host: EmailAddress) -> [EmailAddress] {
        let splitted = plainTextBody.components(separatedBy: .whitespaces)
        
        if
            Command.isAddFollowerInput(input: plainTextBody),
            splitted.count > 2
        {
            let possibleAddresses = splitted[2..<splitted.count]
            let validAddresses = possibleAddresses.filter { $0.isValidEmail() }
            return validAddresses.compactMap { EmailAddress(displayName: "", address: $0) }
        }

        return []
    }
}
