//
//  SetProfilePicSucceededCommandResult.swift
//
//
//  Created by Philip Loden on 1/7/23.
//

import Foundation
import SerializedSwift

public class SetProfilePicSucceededCommandResult: CommandResult {
    /*
    enum CodingKeys: String, CodingKey {
        case profilePicURL
    }
     */
    
    /*
    //@Serialized
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
    var profilePicURL: URL
    
    public required init() {
        super.init()
        profilePicURL = URL(string: "http://google.com")!
    }
    
    public required init(createCommandMessageID: MessageID, commandType: CommandType, command: Command, user: EmailAddress, message: String, exitCode: CommandExitCode, profilePicURL: URL) {
        super.init(createCommandMessageID: createCommandMessageID, commandType: commandType, command: command, message: message, exitCode: exitCode)
        /*
        self.createCommandMessageID = createCommandMessageID
        self.commandType = commandType
        self.command = command
        self.user = user
        self.message = message
        self.exitCode = exitCode
         */
        self.profilePicURL = profilePicURL
    }
    
     /*
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
     */
    
    public override func hash(into hasher: inout Hasher) {
        hasher.combine(command)
        //hasher.combine(commandType)
        //hasher.combine(sender)
        //hasher.combine(receiver)
        hasher.combine(createCommandMessageID)
    }
}

public extension SetProfilePicSucceededCommandResult {
    static func == (lhs: SetProfilePicSucceededCommandResult, rhs: SetProfilePicSucceededCommandResult) -> Bool {
        return lhs.createCommandMessageID == rhs.createCommandMessageID &&
        lhs.command == rhs.command
    }
    
}
