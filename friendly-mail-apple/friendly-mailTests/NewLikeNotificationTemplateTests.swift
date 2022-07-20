//
//  NewLikeNotificationTemplateTests.swift
//  friendly-mailTests
//
//  Created by Philip Loden on 3/25/22.
//

import XCTest
@testable import friendly_mail_core
@testable import friendly_mail_ios

class NewLikeNotificationTemplateTests: XCTestCase {

    func test() throws {
        var uid: UInt64 = 1
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let theme = (UIApplication.shared.delegate as! AppDelegate).appConfig.themes.first(where: { $0.name == "Victor" })!
        let settings = TestSettings(user: user, password: "", selectedTheme: theme)
        
        var messages = MessageStore()
        
        MessageReceiverTests.loadCreateSubscriptionEmail(testCase: self, uid: &uid, settings: settings, messages: &messages)
        MessageReceiverTests.loadCreatePostEmail(testCase: self, uid: &uid, settings: settings, messages: &messages)
        MessageReceiverTests.loadCreateLikeEmail(testCase: self, uid: &uid, settings: settings, messages: &messages)
        
        let newLikeNotification = MailController.unsentNewLikeNotifications(settings: settings, messages: messages).first!
        let withMessages = MailController.newLikeNotificationWithMessages(for: [newLikeNotification], messages: messages).first!
        
        let template = NewLikeNotificationTemplate(theme: theme)
        //template.htmlTemplateFilename = "new_like_notification_template_working"
        
        let createLike = withMessages.createLikeMessage
        let createPost = withMessages.createPostMessage
        let html = template.populateHTML(notification: newLikeNotification, createLikeMessage: createLike, createPostMessage: createPost)!
        print(html)
        
        let htmlPath = Bundle(for: type(of: self )).path(forResource: "expected_html", ofType: "html", inDirectory: "NewLikeNotificationTemplateTests")!
        let expectedHTML = try! String(contentsOf: URL(fileURLWithPath: htmlPath))

        XCTAssert(html == expectedHTML)
    }
    
}
