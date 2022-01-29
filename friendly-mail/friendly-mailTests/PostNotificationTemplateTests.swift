//
//  PostNotificationTemplateTests.swift
//  friendly-mailTests
//
//  Created by Philip Loden on 10/21/21.
//

import XCTest
@testable import friendly_mail

class PostNotificationTemplateTests: XCTestCase {

    /*
    func testPlainText() {
        let authorAddress = TestHelpers.testAddress()
        let createPostMessage = TestHelpers.testCreatePostMessage(author: authorAddress)
        
        let expected =
"""
\(authorAddress.name) updated their status:

"\(createPostMessage.post.articleBody)"

Thanks,
The Friendly-Mail Team
"""
        
        let template = PostNotificationTemplate()
        let populated = template.populatePlainText(with: createPostMessage.post)
        
        let populatedLines = populated!.split(separator: "\n")
        let expectedLines = expected.split(separator: "\n")
        
        //XCTAssert(populated! == expected)
        
        for idx in 0..<expectedLines.count {
            let pop = populatedLines[idx]
            let exp = expectedLines[idx]
            XCTAssert(pop == exp, "expected:\n\(exp)\n actual:\n\(pop)\n")
        }
    }
     */
}
