//
//  AppDelegate.swift
//  friendly-mail
//
//  Created by Philip Loden on 7/17/21.
//

import UIKit
import AppAuth

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var currentAuthorizationFlow: OIDExternalUserAgentSession?
    var authState: OIDAuthState?
    
    lazy var settings: Settings = {
        if let existing = Settings(fromUserDefaults: .standard) {
            return existing
        } else {
            let user = Address(name: "", address: "")!
            let new = Settings(user: user, password: "")
            _ = new.save(toUserDefaults: .standard)
            return new
        }
    }()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        Settings.addObserver(forSettings: self)
        
        SettingsSynchronizer.shared.synciCloud()

        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
      SettingsSynchronizer.shared.synciCloud()
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:] ) -> Bool {
        // Determine who sent the URL.
        let sendingAppID = options[.sourceApplication]
        print("source application = \(sendingAppID ?? "Unknown")")
        // Process the URL.
        if
            let currentAuthorizationFlow = currentAuthorizationFlow,
            currentAuthorizationFlow.resumeExternalUserAgentFlow(with: url)
        {
            self.currentAuthorizationFlow = nil
        }
        return true
    }
    
}

extension AppDelegate: SettingsObserver {
    func settingsDidChange(_ notification: Foundation.Notification) {
        OperationQueue.main.addOperation {
            if let loaded = Settings(fromUserDefaults: .standard) {
                self.settings = loaded
                _ = self.settings.save(toKeyValueStore: NSUbiquitousKeyValueStore.default)
                SettingsSynchronizer.shared.synciCloud()
            }
        }
    }
}
