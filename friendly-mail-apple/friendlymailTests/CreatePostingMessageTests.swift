//
//  CreatePostMessageTests.swift
//  friendlymailTests
//
//  Created by Philip Loden on 3/17/22.
//

import XCTest
@testable import friendlymail_core
@testable import friendlymail_ios

class CreatePostMessageTests: XCTestCase {
    
    /*
     A create post email exists. Was a corresponding CreatePostingMessage object created?
     */
    /*
    func testCreatePostMessage() throws {
        let uid: UInt64 = 1
                        
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let theme = (UIApplication.shared.delegate as! AppDelegate).appConfig.defaultTheme
        let settings = TestSettings(user: user, password: "", selectedTheme: theme)
         
        let path = Bundle(for: type(of: self )).path(forResource: "hello_world", ofType: "txt")!
        let message = TestHelpers.loadEmail(account: account, withPath: path, uid: uid)
        
        XCTAssertNotNil(message)
        XCTAssert(message is CreatePostingMessage)
        
        let createPostMessage = message as! CreatePostingMessage
        XCTAssertEqual("hello, world", createPostMessage.post.articleBody)
    }
     */

}
