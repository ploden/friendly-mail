//
//  File.swift
//  
//
//  Created by Philip Loden on 11/21/22.
//

import Foundation

public struct CommandController {
    
    static func handleCreateAccount(createCommandsMessage: CreateCommandsMessage, command: Command, messages: MessageStore, host: Address) -> CommandResult {
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
            return result
        } else if
            let account = messages.account
        {
            if fromUser == account.user {
                let message = "account already exists for \(account.user.address)"
                
                let result = CommandResult(createCommandMessageID: command.createCommandsMessageID,
                                           commandType: command.commandType,
                                           command: command,
                                           user: fromUser,
                                           message: message,
                                           exitCode: .fail)
                return result
            } else {
                let message = "permission denied"
                
                let result = CommandResult(createCommandMessageID: command.createCommandsMessageID,
                                           commandType: command.commandType,
                                           command: command,
                                           user: fromUser,
                                           message: message,
                                           exitCode: .fail)
                return result
            }
        } else {
            let message = "an unknown error occurred"
            
            let result = CommandResult(createCommandMessageID: command.createCommandsMessageID,
                                       commandType: command.commandType,
                                       command: command,
                                       user: fromUser,
                                       message: message,
                                       exitCode: .fail)
            return result
        }
    }

}
