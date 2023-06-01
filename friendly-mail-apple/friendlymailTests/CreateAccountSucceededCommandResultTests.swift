//
//  CreateAccountSucceededCommandResultTests.swift
//  friendlymail-ios-Tests
//
//  Created by Philip Loden on 12/21/22.
//

import XCTest
@testable import friendlymail_ios
@testable import friendlymail_core

final class CreateAccountSucceededCommandResultTests: XCTestCase {

    func testEncodeDecode() throws {
        let user = EmailAddress(displayName: nil, address: "ploden@gmail.com")!
        let command = Command(index: 0, commandType: .createAccount, createCommandsMessageID: "anID", input: "useradd", host: user, user: user)
        let account = FriendlyMailUser(email: user)
        let inCommandResult = CreateAccountSucceededCommandResult(createCommandMessageID: "anID", commandType: .createAccount, command: command, message: "success", exitCode: .success, account: account)
        
        let inDict: [String:CommandResult] = ["commandResult": inCommandResult]
        
        let jsonData = try! JSONEncoder().encode(inDict)
        
        let decoder = JSONDecoder()
        
        let outDict = try! decoder.decode([String:CreateAccountSucceededCommandResult].self, from: jsonData)
        let outCommandResult = outDict["commandResult"]
        
        XCTAssert(inCommandResult == outCommandResult)
    }

}
