//
//  AddFollowersSucceededCommandResult.swift
//  
//
//  Created by Philip Loden on 1/28/23.
//

import Foundation

public class AddFollowersSucceededCommandResult: CommandResult {
    enum CodingKeys: String, CodingKey {
        case follows
    }
    
    var followee: Address {
        get {
            return user
        }
    }
    let follows: [Follow]
    
    public required init(createCommandMessageID: MessageID, commandType: CommandType, command: Command, user: Address, message: String, exitCode: CommandExitCode, follows: [Follow]) {
        self.follows = follows
        super.init(createCommandMessageID: createCommandMessageID, commandType: commandType, command: command, user: user, message: message, exitCode: exitCode)
    }
    
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
}
