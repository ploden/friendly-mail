//
//  AddFollowersSucceededCommandResult.swift
//  
//
//  Created by Philip Loden on 1/28/23.
//

import Foundation
import SerializedSwift

public class AddFollowersSucceededCommandResult: CommandResult {
    /*
    enum CodingKeys: String, CodingKey {
        case follows
    }
     */
    
    /*
    public var createCommandMessageID: MessageID
    //@Serialized
    public var commandType: CommandType
    //@Serialized
    public var command: Command
    //@Serialized
    public var user: Address
    //@Serialized
    public var message: String
    //@Serialized
    public var exitCode: CommandExitCode
     */
    
    @Serialized
    var followee: Address
    @Serialized
    var follows: [Follow]
    
    public required init() {
        super.init()
    }
    
    public required init(createCommandMessageID: MessageID, commandType: CommandType, command: Command, user: Address, message: String, exitCode: CommandExitCode, follows: [Follow]) {
        super.init(createCommandMessageID: createCommandMessageID, commandType: commandType, command: command, message: message, exitCode: exitCode)
        /*
        self.createCommandMessageID = createCommandMessageID
        self.commandType = commandType
        self.command = command
        self.user = user
        self.message = message
        self.exitCode = exitCode
         */
        self.followee = user
        self.follows = follows
    }
    
    /*
    public required convenience init(from decoder: Decoder) throws {
        let commandResult = try CommandResult.init(from: decoder)
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let follows = try values.decode([Follow].self, forKey: .follows)
        
        self.init(createCommandMessageID: commandResult.createCommandMessageID,
                  commandType: commandResult.commandType,
                  command: commandResult.command,
                  user: commandResult.user,
                  message: commandResult.message,
                  exitCode: commandResult.exitCode,
                  follows: follows)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(follows, forKey: .follows)
    }
     */
    
    override public func hash(into hasher: inout Hasher) {
        hasher.combine(command)
        //hasher.combine(commandType)
        //hasher.combine(sender)
        //hasher.combine(receiver)
        hasher.combine(createCommandMessageID)
    }
}

public extension AddFollowersSucceededCommandResult {
    static func == (lhs: AddFollowersSucceededCommandResult, rhs: AddFollowersSucceededCommandResult) -> Bool {
        return lhs.createCommandMessageID == rhs.createCommandMessageID &&
        lhs.command == rhs.command
    }
    
}
