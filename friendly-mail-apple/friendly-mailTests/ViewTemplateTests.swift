//
//  ViewTemplateTests.swift
//  friendly-mailTests
//
//  Created by Philip Loden on 2/15/22.
//

import XCTest
@testable import friendly_mail_ios
@testable import friendly_mail_core

class ViewTemplateTests: XCTestCase {
    /*
    var webVC = WebViewController()
        
    override func setUp() {
        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
            sceneDelegate.rootViewControllerOverride = webVC
        }
        
        super.setUp()
    }
     */
    
    /*
    func testViewNewLikeNotificationEmail() throws {
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
        template.htmlTemplateFilename = "new_like_notification_template_working"
        
        let createLike = withMessages.createLikeMessage
        let createPost = withMessages.createPostMessage
        let html = template.populateHTML(notification: newLikeNotification, createLikeMessage: createLike, createPostMessage: createPost)!
            
        webVC.webView.loadHTMLString(html, baseURL: nil)

        ViewTemplateTests.spinRunLoopWithBool() { _ in
            var stop: Int = 1
            let huh = template.populateHTML(notification: newLikeNotification, createLikeMessage: createLike, createPostMessage: createPost)!
            let web = webVC
            return stop
        }
    }
     */
    
    /*
    func testViewNewPostNotificationEmail() throws {
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
        webVC.webView.loadHTMLString(html, baseURL: nil)
        
        ViewTemplateTests.spinRunLoopWithBool() { _ in
            var stop: Int = 1
            return stop
        }
    }
    
    class func spinRunLoopWithBool(_ handler: (Bool) -> (Int)) {
        var stop = false
        
        while true {
            if handler(true) == 1 {
                break
            } else {
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 1.0))
            }
        }
    }
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    class WebViewController: UIViewController {
        var webView = UIWebView()

        override func viewDidLoad() {
            super.viewDidLoad()
            
            webView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(webView)
            
            let constraints = [.top, .bottom, .right, .left].map {
                NSLayoutConstraint(item: webView, attribute: $0, relatedBy: .equal, toItem: view, attribute: $0, multiplier: 1, constant: 0)
            }
            constraints.forEach { view.addConstraint($0) }
        }
        
    }
     */
    
}
