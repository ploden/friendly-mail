//
//  MailProviderTests.swift
//  friendlymail-ios-Tests
//
//  Created by Philip Loden on 10/25/22.
//

import XCTest
@testable import friendlymail_ios
@testable import friendlymail_core

class MailProviderTests: XCTestCase {

    /*
    func testAttachments() throws {
        // Load email from file
        let path = Bundle(for: type(of: self )).path(forResource: "create_posting_with_image", ofType: "txt")!

        let uid: UInt64 = 1
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com", isHost: true)!
        let theme = (UIApplication.shared.delegate as! AppDelegate).appConfig.defaultTheme
        let correctSettings = TestSettings(user: user, password: "", selectedTheme: theme)
        let correctMessage = TestHelpers.loadEmail(accountAddress: user, withPath: path, uid: uid)
        
        XCTAssert(correctMessage!.attachments!.count == 3)
        let jpeg = correctMessage!.attachments!.first { $0.mimeType == "image/jpeg" }
        XCTAssertNotNil(jpeg)
    }
     */

}
