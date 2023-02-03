//
//  SetProfilePicSucceededCommandResult.swift
//
//
//  Created by Philip Loden on 1/7/23.
//

import Foundation

public class SetProfilePicSucceededCommandResult: CommandResult {
    enum CodingKeys: String, CodingKey {
        case profilePicURL
    }
    
    let profilePicURL: URL
    
    public required init(createCommandMessageID: MessageID, commandType: CommandType, command: Command, user: Address, message: String, exitCode: CommandExitCode, profilePicURL: URL) {
        self.profilePicURL = profilePicURL
        super.init(createCommandMessageID: createCommandMessageID, commandType: commandType, command: command, user: user, message: message, exitCode: exitCode)
    }
    
    public required convenience init(from decoder: Decoder) throws {
        let commandResult = try CommandResult.init(from: decoder)
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let profilePicURL = try values.decode(URL.self, forKey: .profilePicURL)
        
        self.init(createCommandMessageID: commandResult.createCommandMessageID,
                  commandType: commandResult.commandType,
                  command: commandResult.command,
                  user: commandResult.user,
                  message: commandResult.message,
                  exitCode: commandResult.exitCode,
                  profilePicURL: profilePicURL)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(profilePicURL, forKey: .profilePicURL)
    }
}
