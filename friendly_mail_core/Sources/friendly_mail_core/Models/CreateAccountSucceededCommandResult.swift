//
//  CreateAccountSucceededCommandResult.swift
//  
//
//  Created by Philip Loden on 12/1/22.
//

import Foundation
import SerializedSwift
import Stencil

public class CreateAccountSucceededCommandResult: CommandResult {
    public override subscript(dynamicMember member: String) -> Any? {
        if member == "account" {
            return account
        }
        return super[dynamicMember: member]
    }
    /*
    enum CodingKeys: String, CodingKey {
        case account
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
    var account: FriendlyMailAccount
    
    public required init() {
        super.init()
        account = FriendlyMailAccount(user: Address(address: ""))
    }
    
    public required init(createCommandMessageID: MessageID, commandType: CommandType, command: Command, user: Address, message: String, exitCode: CommandExitCode, account: FriendlyMailAccount) {
        super.init(createCommandMessageID: createCommandMessageID, commandType: commandType, command: command, message: message, exitCode: exitCode)
        /*
        self.createCommandMessageID = createCommandMessageID
        self.commandType = commandType
        self.command = command
        self.user = user
        self.message = message
        self.exitCode = exitCode
         */
        self.account = account
    }
    
     /*
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
    }
     */
}

public extension CreateAccountSucceededCommandResult {
    static func == (lhs: CreateAccountSucceededCommandResult, rhs: CreateAccountSucceededCommandResult) -> Bool {
        return lhs.createCommandMessageID == rhs.createCommandMessageID &&
        lhs.command == rhs.command
    }
    
    /*
    func hash(into hasher: inout Hasher) {
        hasher.combine(command)
        //hasher.combine(commandType)
        //hasher.combine(sender)
        //hasher.combine(receiver)
        hasher.combine(createCommandMessageID)
    }
     */
}
