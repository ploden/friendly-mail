//
//  FriendlyMailMessageTests.swift
//  friendly-mailTests
//
//  Created by Philip Loden on 8/20/21.
//

import XCTest
@testable import friendly_mail

class FriendlyMailMessageTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testJSON() throws {
        //let html = "<div style=\"padding-bottom: 20px;\"></div><div>&#128077;&#127995;\r<br/>\r<br/>{\'action\':\'like\',\'messageID\':\'D08515C5-1D77-4BE5-8863-1AD99BBE237B@gmail.com\'}<br/></div>"
        /*
        let html = "<div style=\"padding-bottom: 20px;\"></div><div>&#128077;&#127995;\r<br/>\r<br/>{\"action\":\"like\",\"messageID\":\"D08515C5-1D77-4BE5-8863-1AD99BBE237B@gmail.com\"}<br/></div>"
        let jsonString = FriendlyMailMessage.extractJSONString(string: html)
        XCTAssertNotNil(jsonString)
        let json = FriendlyMailMessage.extractJSON(string: jsonString!)
        XCTAssertNotNil(json)
        
        let plainTextSingleQuotes = "👍🏻 {\'action\':\'like\',\'messageID\':\'D08515C5-1D77-4BE5-8863-1AD99BBE237B@gmail.com\'}"
        let jsonStringFromPlainText = FriendlyMailMessage.extractJSONString(string: plainTextSingleQuotes)
        XCTAssertNotNil(jsonStringFromPlainText)
        let jsonFromPlainText = FriendlyMailMessage.extractJSON(string: jsonStringFromPlainText!)
        XCTAssertNotNil(jsonFromPlainText)
         */
    }
    
}
