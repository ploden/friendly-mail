//
//  AppleStorageProviderTests.swift
//  friendly-mail-ios-Tests
//
//  Created by Philip Loden on 1/2/23.
//

import XCTest
@testable import friendly_mail_ios
@testable import friendly_mail_core

final class AppleStorageProviderTests: XCTestCase {

    func testUpload() throws {
        let storageProvider = (UIApplication.shared.delegate as? AppDelegate)!.storageProvider

        let now = Date.now
        let nowString = "\(now.timeIntervalSince1970)"
        let nowData = nowString.data(using: .utf8)!
        
        let expectation = XCTestExpectation(description: "Wait for upload.")

        storageProvider.uploadData(data: nowData, filename: nowString, contentType: "text/plain") { error, url in
            XCTAssertNil(error)
            XCTAssertNotNil(url)
            print(url!)
            expectation.fulfill()
        }
        
        let _ = XCTWaiter.wait(for: [expectation], timeout: 20.0)
    }

}
