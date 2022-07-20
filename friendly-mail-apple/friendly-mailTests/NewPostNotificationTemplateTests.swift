//
//  NewPostNotificationTemplateTests.swift
//  friendly-mailTests
//
//  Created by Philip Loden on 3/25/22.
//

import XCTest
@testable import friendly_mail_core
@testable import friendly_mail_ios

class NewPostNotificationTemplateTests: XCTestCase {

    func test() throws {
        var uid: UInt64 = 1
        let user = Address(name: "Phil Loden", address: "ploden@gmail.com")!
        let theme = (UIApplication.shared.delegate as! AppDelegate).appConfig.themes.first(where: { $0.name == "Victor" })!
        let settings = TestSettings(user: user, password: "", selectedTheme: theme)

        var messages = MessageStore()

        MessageReceiverTests.loadCreateSubscriptionEmail(testCase: self, uid: &uid, settings: settings, messages: &messages)
        MessageReceiverTests.loadCreatePostEmail(testCase: self, uid: &uid, settings: settings, messages: &messages)
        
        let subscription = MailController.subscriptions(forAddress: settings.user, messages: messages).first!
        let unsentNewPostNotification = MailController.unsentNewPostNotifications(settings: settings, messages: messages, for: subscription).first!
            
        let template = NewPostNotificationTemplate(theme: theme)
        let html = template.populateHTML(with: unsentNewPostNotification.createPostMessage.post, notification: unsentNewPostNotification.notification, subscription: subscription)!
        print(html)
        
        let htmlPath = Bundle(for: type(of: self )).path(forResource: "expected_html", ofType: "html", inDirectory: "NewPostNotificationTemplateTests")!
        let expectedHTML = try! String(contentsOf: URL(fileURLWithPath: htmlPath))
        
        XCTAssert(html == expectedHTML)
    }

}
