//
//  CreateAccountSucceededCommandResultTests.swift
//  friendly-mail-ios-Tests
//
//  Created by Philip Loden on 12/21/22.
//

import XCTest
@testable import friendly_mail_ios
@testable import friendly_mail_core

final class CreateAccountSucceededCommandResultTests: XCTestCase {

    func testEncodeDecode() throws {
        let command = Command(index: 0, commandType: .createAccount, createCommandsMessageID: "anID", input: "create account")
        let user = Address(name: nil, address: "ploden@gmail.com")!
        let account = FriendlyMailAccount(user: user)
        let inCommandResult = CreateAccountSucceededCommandResult(createCommandMessageID: "anID", commandType: .createAccount, command: command, user: user, message: "success", exitCode: .success, account: account)
        
        let inDict: [String:CommandResult] = ["commandResult": inCommandResult]
        
        let jsonData = try! JSONEncoder().encode(inDict)
        
        let decoder = JSONDecoder()
        
        let outDict = try! decoder.decode([String:CreateAccountSucceededCommandResult].self, from: jsonData)
        let outCommandResult = outDict["commandResult"]
        
        XCTAssert(inCommandResult == outCommandResult)
    }

}
