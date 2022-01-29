//
//  MessageHeaderTests.swift
//  friendly-mailTests
//
//  Created by Philip Loden on 12/9/21.
//

import XCTest
@testable import friendly_mail

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

}
