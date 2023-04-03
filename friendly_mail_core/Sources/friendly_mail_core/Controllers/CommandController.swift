//
//  File.swift
//  
//
//  Created by Philip Loden on 11/21/22.
//

import Foundation

public struct CommandController {
    
    static func handleCreateAccount(createCommandsMessage: CreateCommandsMessage, command: Command, messages: MessageStore, host: Address, theme: Theme) -> [AnyMessageDraft] {
        let fromUser = createCommandsMessage.header.fromAddress
        
        if
            messages.account == nil,
            fromUser == host
        {
            let message = "account created for \(fromUser.address)"
            
            let account = FriendlyMailAccount(user: fromUser)
            
            let result = CreateAccountSucceededCommandResult(createCommandMessageID: command.createCommandsMessageID,
                                                             commandType: command.commandType,
                                                             command: command,
                                                             user: fromUser,
                                                             message: message,
                                                             exitCode: .success,
                                                             account: account)
            
            let commandResultDraft = CommandResultMessageDraft(to: [account.user], commandResults: [result], theme: theme)
            
            let plainTextBody = "Fm: add follower \(account.user.address)"
            let followMessageDraft = MessageDraft(to: [account.user], subject: Constants.fmSubject.rawValue, htmlBody: nil, plainTextBody: plainTextBody, friendlyMailHeaders: nil)

            return [commandResultDraft!, followMessageDraft]
        } else if
            let account = messages.account
        {
            guard Self.hasPermission(createCommandsMessage: createCommandsMessage, command: command, messages: messages) else {
                let result = Self.createPermissionDeniedCommandResult(createCommandsMessage: createCommandsMessage, command: command)
                let commandResultDraft = CommandResultMessageDraft(to: [account.user], commandResults: [result], theme: theme)
                return [commandResultDraft!]
            }
            if fromUser == account.user {
                let message = "account already exists for \(account.user.address)"
                
                let result = CommandResult(createCommandMessageID: command.createCommandsMessageID,
                                           commandType: command.commandType,
                                           command: command,
                                           message: message,
                                           exitCode: .fail)
                let commandResultDraft = CommandResultMessageDraft(to: [account.user], commandResults: [result], theme: theme)
                return [commandResultDraft!]
            }
        }
        let result = Self.createUnknownErrorCommandResult(createCommandsMessage: createCommandsMessage, command: command)
        let commandResultDraft = CommandResultMessageDraft(to: [host], commandResults: [result], theme: theme)
        return [commandResultDraft!]
    }

    static func handleSetProfilePic(createCommandsMessage: CreateCommandsMessage,
                                    command: Command,
                                    messages: MessageStore,
                                    storageProvider: StorageProvider) async -> CommandResult
    {
        guard Self.hasPermission(createCommandsMessage: createCommandsMessage, command: command, messages: messages) else {
            return Self.createPermissionDeniedCommandResult(createCommandsMessage: createCommandsMessage, command: command)
        }
        
        let fromUser = createCommandsMessage.header.fromAddress
        
        if let account = messages.account {
            // upload the image
            let mimeType = "image/jpeg"
            
            if let photoAttachment = createCommandsMessage.attachments!.first(where: { $0.mimeType == mimeType }) {
                let filename = UUID().uuidString
                
                return await withCheckedContinuation { continuation in
                    storageProvider.uploadData(data: photoAttachment.data, filename: filename, contentType: mimeType) { error, url in
                        if let url = url {
                            let message = "successfully updated profile pic for \(account.user.address)"
                            
                            let result = SetProfilePicSucceededCommandResult(createCommandMessageID: command.createCommandsMessageID,
                                                                             commandType: command.commandType,
                                                                             command: command,
                                                                             user: fromUser,
                                                                             message: message,
                                                                             exitCode: .success,
                                                                             profilePicURL: url)
                            continuation.resume(returning: result)
                        } else {
                            let message = "update profile pic failed"
                            
                            let result = CommandResult(createCommandMessageID: command.createCommandsMessageID,
                                                       commandType: command.commandType,
                                                       command: command,
                                                       message: message,
                                                       exitCode: .fail)
                            continuation.resume(returning: result)
                        }
                    }
                }
            } else {
                let message = "image not found"
                
                let result = CommandResult(createCommandMessageID: command.createCommandsMessageID,
                                           commandType: command.commandType,
                                           command: command,
                                           message: message,
                                           exitCode: .fail)
                return result
            }
        }
        
        return Self.createUnknownErrorCommandResult(createCommandsMessage: createCommandsMessage, command: command)
    }
    
    static func handleAddFollowers(createCommandsMessage: CreateCommandsMessage, command: Command, messages: MessageStore, host: Address) -> CommandResult {
        guard Self.hasPermission(createCommandsMessage: createCommandsMessage, command: command, messages: messages) else {
            return Self.createPermissionDeniedCommandResult(createCommandsMessage: createCommandsMessage, command: command)
        }
        
        let followersToAdd = MessageFactory.extractFollowersToAdd(plainTextBody: command.input)
        
        if let result = Self.createAddFollowersSucceededCommandResult(createCommandsMessage: createCommandsMessage, command: command, followersToAdd: followersToAdd) {
            return result
        } else {
            return Self.createUnknownErrorCommandResult(createCommandsMessage: createCommandsMessage, command: command)
        }
    }
    
    static func hasPermission(createCommandsMessage: CreateCommandsMessage, command: Command, messages: MessageStore) -> Bool {
        let fromUser = createCommandsMessage.header.fromAddress
        
        if
            let account = messages.account,
            fromUser == account.user
        {
            return true
        }
        return false
    }
    
    static func createPermissionDeniedCommandResult(createCommandsMessage: CreateCommandsMessage, command: Command) -> CommandResult {
        let message = "permission denied"
        
        let result = CommandResult(createCommandMessageID: command.createCommandsMessageID,
                                   commandType: command.commandType,
                                   command: command,
                                   message: message,
                                   exitCode: .fail)
        return result
    }
    
    static func createUnknownErrorCommandResult(createCommandsMessage: CreateCommandsMessage, command: Command) -> CommandResult {
        let message = "an unknown error occurred"
        
        let result = CommandResult(createCommandMessageID: command.createCommandsMessageID,
                                   commandType: command.commandType,
                                   command: command,
                                   message: message,
                                   exitCode: .fail)
        return result
    }
    
    static func createAddFollowersSucceededCommandResult(createCommandsMessage: CreateCommandsMessage, command: Command, followersToAdd: [Address]) -> AddFollowersSucceededCommandResult? {
        let follows = followersToAdd.map {
            Follow(follower: $0, followee: createCommandsMessage.header.fromAddress, frequency: .undefined, messageID: createCommandsMessage.header.messageID)
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
}
