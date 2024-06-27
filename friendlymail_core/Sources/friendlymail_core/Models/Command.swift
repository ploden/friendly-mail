//
//  Command.swift
//  
//
//  Created by Philip Loden on 10/19/22.
//

import Foundation

public enum CommandType: String, Codable, CaseIterable {
    case createAccount = "useradd"
    case setProfilePic = "usermod"
    case unknown
    case createInvites = "invite"
    case follow = "follow"
    case help = "help"
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
    let user: EmailAddress
    let host: EmailAddress
    
    public init(index: Int, commandType: CommandType, createCommandsMessageID: MessageID, input: String, host: EmailAddress, user: EmailAddress) {
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
            ["follow add", "follow -a"].contains("\(splitted[0]) \(splitted[1])".lowercased())
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
