//
//  CommandResult.swift
//  
//
//  Created by Philip Loden on 11/3/22.
//

import Foundation
import SerializedSwift
import Stencil

public enum CommandExitCode: Int, Codable {
    case success = 0
    case fail = 1
}

public class CommandResult: Equatable, Hashable, Serializable {
    public required init() {
        createCommandMessageID = MessageID()
        commandType = .unknown
        command = Command(index: 0,
                          commandType: .unknown,
                          createCommandsMessageID: createCommandMessageID,
                          input: "",
                          host: EmailAddress(address: EmailAddress.nullAddress)!,
                          user: EmailAddress(address: EmailAddress.nullAddress)!)
    }
    
    @Serialized
    public var createCommandMessageID: MessageID
    @Serialized
    public var commandType: CommandType
    @Serialized
    public var command: Command
    public var user: EmailAddress {
        get {
            return command.user
        }
    }
    public var host: EmailAddress {
        get {
            return command.host
        }
    }
    @Serialized
    public var message: String
    @Serialized
    public var exitCode: CommandExitCode
    
    public init(createCommandMessageID: MessageID, commandType: CommandType, command: Command, message: String, exitCode: CommandExitCode) {
        self.createCommandMessageID = createCommandMessageID
        self.commandType = commandType
        self.command = command
        self.message = message
        self.exitCode = exitCode
    }
        
    /*
    public required convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let aUser = try values.decode(Address.self, forKey: .user)
        let aMessage = try values.decode(String.self, forKey: .message)
        let aCreateCommandMessageID = try values.decode(MessageID.self, forKey: .createCommandMessageID)
        let aCommandType = try values.decode(CommandType.self, forKey: .commandType)
        let anExitCode = try values.decode(CommandExitCode.self, forKey: .exitCode)
        
        let aCommand = try! values.decode(Command.self, forKey: .command)

        self.init(createCommandMessageID: aCreateCommandMessageID, commandType: aCommandType, command: aCommand, user: aUser, message: aMessage, exitCode: anExitCode)
        switch aCommandType {
        case .createAccount:
            CreateAccountSucceededCommandResult.init(createCommandMessageID: aCreateCommandMessageID, commandType: aCommandType, command: aCommand, user: aUser, message: aMessage, exitCode: anExitCode, account: FriendlyMailAccount(user: Address(address: "")))
        case .setProfilePic:
            return try! SetProfilePicSucceededCommandResult.init(from: decoder)
        case .addFollowers:
            return try! AddFollowersSucceededCommandResult.init(from: decoder)
        default:
            self.init(createCommandMessageID: aCreateCommandMessageID, commandType: aCommandType, command: aCommand, user: aUser, message: aMessage, exitCode: anExitCode)
        }
    }
    */
    
    /*
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(user, forKey: .user)
        try container.encode(message, forKey: .message)
        try container.encode(createCommandMessageID, forKey: .createCommandMessageID)
        try container.encode(commandType.rawValue, forKey: .commandType)

        try container.encode(command, forKey: .command)

        try container.encode(exitCode.rawValue, forKey: .exitCode)
        
        switch commandType {
        case .createAccount:
            try container.encode(command, forKey: .commandType)
        case .setProfilePic:
            command = try values.decode(ChangeProfilePicCommand.self, forKey: .command)
        case .unknown:
            command = try values.decode(UnknownCommand.self, forKey: .command)
        }
    }
     */
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(command)
        hasher.combine(createCommandMessageID)
        hasher.combine(message)
    }
}

public extension CommandResult {
    static func == (lhs: CommandResult, rhs: CommandResult) -> Bool {
        return lhs.createCommandMessageID == rhs.createCommandMessageID &&
        lhs.command == rhs.command
    }
}

extension CommandResult: Base64JSONCodable {}
