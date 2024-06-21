//
//  UseraddCommandController.swift
//  
//
//  Created by Philip Loden on 4/28/23.
//

import Foundation

public struct UseraddCommandController {
    
    static func handleCreateAccount(command: Command, messages: MessageStore, host: EmailAddress, theme: Theme) -> [MessageDraftProtocol] {
        if
            messages.hostUser == nil,
            command.user.id == command.host.id
        {
            let message = "account created for \(command.user.address)"
            
            let account = FriendlyMailUser(email: command.user)
            
            let result = CreateAccountSucceededCommandResult(createCommandMessageID: command.createCommandsMessageID,
                                                             commandType: command.commandType,
                                                             command: command,
                                                             message: message,
                                                             exitCode: .success,
                                                             account: account)
            
            let commandResultDraft = CommandResultMessageDraft(to: [account.email], commandResults: [result], theme: theme)
            
            let plainTextBody = "\(CreateCommandsMessage.commandPrefix)follow add \(account.email.address)"
            let followMessageDraft = MessageDraft(to: [account.email], subject: Constants.fmShortSubject.rawValue, htmlBody: nil, plainTextBody: plainTextBody, friendlyMailHeaders: nil)

            return [commandResultDraft!, followMessageDraft]
        } else if
            let account = messages.hostUser
        {
            guard CommandController.hasPermission(command: command, messages: messages) else {
                let result = CommandController.createPermissionDeniedCommandResult(command: command)
                let commandResultDraft = CommandResultMessageDraft(to: [account.email], commandResults: [result], theme: theme)
                return [commandResultDraft!]
            }
            if command.user.id == account.email.id {
                let message = "account already exists for \(account.email.address)"
                
                let result = CommandResult(createCommandMessageID: command.createCommandsMessageID,
                                           commandType: command.commandType,
                                           command: command,
                                           message: message,
                                           exitCode: .fail)
                let commandResultDraft = CommandResultMessageDraft(to: [account.email], commandResults: [result], theme: theme)
                return [commandResultDraft!]
            }
        }
        let result = CommandController.createUnknownErrorCommandResult(command: command)
        let commandResultDraft = CommandResultMessageDraft(to: [host], commandResults: [result], theme: theme)
        return [commandResultDraft!]
    }
    
}
