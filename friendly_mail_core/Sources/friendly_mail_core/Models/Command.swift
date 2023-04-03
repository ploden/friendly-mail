//
//  Command.swift
//  
//
//  Created by Philip Loden on 10/19/22.
//

import Foundation

public enum CommandType: String, Codable {
    case createAccount = "create account"
    case setProfilePic = "set profile pic"
    case unknown
    case createInvites = "invite"
    case addFollowers = "add follower"
}

public class Command: Codable, Hashable, Equatable {
    /*
     A message can have multiple commands. This is the index
     of this command in the array of commands from the message.
     */
    let index: Int
    static var commandType: CommandType = .unknown
    let commandType: CommandType
    let createCommandsMessageID: MessageID
    let input: String
    let user: Address
    let host: Address
    
    public init(index: Int, commandType: CommandType, createCommandsMessageID: MessageID, input: String, host: Address, user: Address) {
        self.index = index
        self.commandType = commandType
        self.createCommandsMessageID = createCommandsMessageID
        self.input = input
        self.host = host
        self.user = user
    }
    
    static func isAddFollowerInput(input: String) -> Bool {
        let splitted = input.components(separatedBy: .whitespaces)
        
        if
            splitted.count > 1,
            ["add followers", "add follower"].contains("\(splitted[0]) \(splitted[1])".lowercased())
        {
            return true
        }
        return false
    }
}

public extension Command {
    static func == (lhs: Command, rhs: Command) -> Bool {
        return lhs.createCommandsMessageID == rhs.createCommandsMessageID &&
        lhs.index == rhs.index &&
        lhs.input == rhs.input &&
        lhs.commandType == rhs.commandType &&
        lhs.host == rhs.host &&
        lhs.user == rhs.user
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(index)
        hasher.combine(commandType)
        hasher.combine(input)
        hasher.combine(host)
        hasher.combine(createCommandsMessageID)
        hasher.combine(user)
    }
}
