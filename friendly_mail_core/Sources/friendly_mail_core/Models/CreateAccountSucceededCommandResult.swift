//
//  CreateAccountSucceededCommandResult.swift
//  
//
//  Created by Philip Loden on 12/1/22.
//

import Foundation

public class CreateAccountSucceededCommandResult: CommandResult {
    enum CodingKeys: String, CodingKey {
        case account
    }
    
    let account: FriendlyMailAccount
    
    public required init(createCommandMessageID: MessageID, commandType: CommandType, command: Command, user: Address, message: String, exitCode: CommandExitCode, account: FriendlyMailAccount) {
        self.account = account
        super.init(createCommandMessageID: createCommandMessageID, commandType: commandType, command: command, user: user, message: message, exitCode: exitCode)
    }
    
    public required convenience init(from decoder: Decoder) throws {
        let commandResult = try CommandResult.init(from: decoder)
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let account = try values.decode(FriendlyMailAccount.self, forKey: .account)
        
        self.init(createCommandMessageID: commandResult.createCommandMessageID,
                  commandType: commandResult.commandType,
                  command: commandResult.command,
                  user: commandResult.user,
                  message: commandResult.message,
                  exitCode: commandResult.exitCode,
                  account: account)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(account, forKey: .account)

        /*
        switch commandType {
        case .createAccount:
            try container.encode(command, forKey: .commandType)
        case .setProfilePic:
            command = try values.decode(ChangeProfilePicCommand.self, forKey: .command)
        case .unknown:
            command = try values.decode(UnknownCommand.self, forKey: .command)
        }
         */
    }
}
