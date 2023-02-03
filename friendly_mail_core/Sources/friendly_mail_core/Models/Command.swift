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
    public static func == (lhs: Command, rhs: Command) -> Bool {
        return lhs.createCommandsMessageID == rhs.createCommandsMessageID &&
        lhs.index == rhs.index
    }
     */
    
    //let sender: Address
    //let receiver: Address
    /*
     A message can have multiple commands. This is the index
     of this command in the array of commands from the message.
     */
    let index: Int
    static var commandType: CommandType = .unknown
    let commandType: CommandType
    let createCommandsMessageID: MessageID
    let input: String
                
    public init(index: Int, commandType: CommandType, createCommandsMessageID: MessageID, input: String) {
        self.index = index
        self.commandType = commandType
        self.createCommandsMessageID = createCommandsMessageID
        self.input = input
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
        lhs.index == rhs.index
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(index)
        //hasher.combine(commandType)
        //hasher.combine(sender)
        //hasher.combine(receiver)
        hasher.combine(createCommandsMessageID)
    }
}

//typealias Command = (SomeCommand & Codable & Hashable)

/*
public class CreateAccountCommand: Command {
    static var commandType: CommandType = .createAccount
    let index: Int
    let createCommandsMessageID: MessageID
    let input: String
    var commandType: CommandType {
        get {
            return Self.commandType
        }
    }
}
 */

/*
class ChangeProfilePicCommand: Command {
    static var commandType: CommandType = .setProfilePic
    let index: Int
    let createCommandsMessageID: MessageID
    let input: String
    var commandType: CommandType {
        get {
            return Self.commandType
        }
    }
}
 */

/*
class UnknownCommand: Command {
    static var commandType: CommandType = .unknown
    let index: Int
    let createCommandsMessageID: MessageID
    let input: String
    var commandType: CommandType {
        get {
            return Self.commandType
        }
    }
}
 */

/*
class CreateInvitesCommand: Command {
    static var commandType: CommandType = .createInvites
    let index: Int
    let createCommandsMessageID: MessageID
    let input: String
    var commandType: CommandType {
        get {
            return Self.commandType
        }
    }
}
 */

/*
extension CreateAccountCommand: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(index)
        //hasher.combine(commandType)
        //hasher.combine(sender)
        //hasher.combine(receiver)
        hasher.combine(createCommandsMessageID)
    }
}
 */

//extension Command: Codable {}
