//
//  Base64JSONCodableTests.swift
//  friendlymail-ios-Tests
//
//  Created by Philip Loden on 1/17/23.
//

import XCTest
@testable import friendlymail_ios
@testable import friendlymail_core

final class Base64JSONCodableTests: XCTestCase {

    func test() throws {
        let user = EmailAddress(displayName: "Phil Loden", address: "ploden@gmail.com")!
        let command = Command(index: 0, commandType: .unknown, createCommandsMessageID: "12345", input: "aoeu", host: user, user: user)
        let result = CommandResult(createCommandMessageID: "12345", commandType: .unknown, command: command, message: "fail", exitCode: .fail)
        let encodedResult = result.encodeAsBase64JSON()
        let decodedResult = CommandResult.decode(fromBase64JSON: encodedResult)
        XCTAssert(result == decodedResult)
        XCTAssert(result.command == decodedResult!.command)
    }

}
