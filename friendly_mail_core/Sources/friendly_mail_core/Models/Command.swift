//
//  Command.swift
//  
//
//  Created by Philip Loden on 10/19/22.
//

import Foundation

public enum CommandTypes: String {
    case createAccount = "create account"
    case setProfilePic = "set profile pic"
}

public struct Command {
    let user: Address
    let commandType: CommandTypes
    let createCommandsMessageID: MessageID
}

extension Command: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(commandType)
        hasher.combine(createCommandsMessageID)
    }
}
