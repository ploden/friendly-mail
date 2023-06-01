//
//  HelpCommandController.swift
//  
//
//  Created by Philip Loden on 4/29/23.
//

import Foundation

public struct HelpCommandController {
    
    static func handleHelp(command: Command, messages: MessageStore, host: EmailAddress, theme: Theme) -> [AnyMessageDraft] {
        let commands = CommandType.allCases.compactMap {
            return $0 == .unknown ? nil : $0.rawValue
        }
        
        let commandsString = commands.joined(separator: "\n")
                
        let message = """
friendlymail, version ???
These shell commands are defined internally.  Type `help' to see this list.
Type `help name' to find out more about the function `name'.

\(commandsString)
"""
        
        let result = CommandResult(createCommandMessageID: command.createCommandsMessageID,
                                   commandType: command.commandType,
                                   command: command,
                                   message: message,
                                   exitCode: .success)
        
        let commandResultDraft = CommandResultMessageDraft(to: [command.user], commandResults: [result], theme: theme)
        return [commandResultDraft!]
    }
    
}
