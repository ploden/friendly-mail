//
//  MessageHeaderTests.swift
//  friendlymailTests
//
//  Created by Philip Loden on 12/9/21.
//

import XCTest
@testable import friendlymail_core
@testable import GenericJSON

class MessageHeaderTests: XCTestCase {

    func testHeaderHelpers() throws {
        let headerString = " v=1; a=rsa-sha256; c=relaxed/relaxed; d=gmail.com; s=gamma; h=domainkey-signature:received:received:message-id:date:from:to :subject:mime-version:content-type; bh=+JqkmVt+sHDFIGX5jKp3oP18LQf10VQjAmZAKl1lspY=; b=F87jySDZnMayyitVxLdHcQNL073DytKRyrRh84GNsI24IRNakn0oOfrC2luliNvdea LGTk3adIrzt+N96GyMseWz8T9xE6O/sAI16db48q4Iqkd7uOiDvFsvS3CUQlNhybNw8m CH/o8eELTN0zbSbn5Trp0dkRYXhMX8FTAwrH0="
        let keyValues = MessageHeader.headerKeyValues(from: headerString)
        XCTAssert(keyValues.count == 8)
        XCTAssert(keyValues.first(where: { $0.key == "v"})!.value == "1")
        
        let outHeaderString = MessageHeader.headerString(from: keyValues)
        let _ = MessageHeader.headerKeyValues(from: outHeaderString)
        
        for _ in keyValues {
           // XCTAssert(keyValue.value == keyValuesFromOutHeaderString[keyValue.key.rawValue])
        }
    }

    func testEncodeDecodeFriendlyMailHeader() throws {
        let mID = "12345"
        let user = Address(name: nil, address: "ploden@gmail.com", isHost: true)!
        let command = Command(index: 0, commandType: .unknown, createCommandsMessageID: mID, input: "aoeu", host: user, user: user)
        let result = CommandResult(createCommandMessageID: command.createCommandsMessageID,
                                   commandType: command.commandType,
                                   command: command,
                                   message: "message",
                                   exitCode: .fail)
        
        let commandResults = [result]
        
        let commandResultsJSON = try! JSON(encodable: commandResults)
        
        let inJSON: JSON = [
            "commandResults": commandResultsJSON
        ]

        let base64JSONString: String = inJSON.encodeAsBase64JSON()
        
        var friendlyMailHeaders = [HeaderKeyValue]()

        friendlyMailHeaders.append(HeaderKeyValue(key: HeaderKey.base64JSON.rawValue, base64JSONString))

        let outJSON = MessageFactory.json(forFriendlyMailHeader: friendlyMailHeaders)
        
        XCTAssert(inJSON == outJSON)
    }
    
}
