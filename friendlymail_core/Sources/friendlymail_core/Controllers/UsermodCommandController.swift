//
//  UsermodCommandController.swift
//  
//
//  Created by Philip Loden on 4/28/23.
//

import Foundation

public struct UsermodCommandController {
    
    static func handleSetProfilePic(createCommandsMessage: CreateCommandsMessage,
                                    command: Command,
                                    messages: MessageStore,
                                    storageProvider: StorageProvider) async -> CommandResult
    {
        guard CommandController.hasPermission(command: command, messages: messages) else {
            return CommandController.createPermissionDeniedCommandResult(command: command)
        }
        
        let fromUser = createCommandsMessage.header.fromAddress
        
        if let hostUser = messages.hostUser {
            // upload the image
            let mimeType = "image/jpeg"
            
            if let photoAttachment = createCommandsMessage.attachments!.first(where: { $0.mimeType == mimeType }) {
                let filename = UUID().uuidString
                
                return await withCheckedContinuation { continuation in
                    storageProvider.uploadData(data: photoAttachment.data, filename: filename, contentType: mimeType) { error, url in
                        if let url = url {
                            let message = "successfully updated profile pic for \(hostUser.email.address)"
                            
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
        
        return CommandController.createUnknownErrorCommandResult(command: command)
    }
    
}
