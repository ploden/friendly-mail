//
//  AppDelegate.swift
//  friendly-mail
//
//  Created by Philip Loden on 7/17/21.
//

import UIKit
import AppAuth
import BackgroundTasks
import friendly_mail_core
import Amplify
import AWSCognitoAuthPlugin
import AWSS3StoragePlugin

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var currentAuthorizationFlow: OIDExternalUserAgentSession?
    var authState: OIDAuthState?
    static var backgroundAppRefreshTaskSchedulerIdentifier = "com.deovolentellc.friendly-mail-ios.backgroundAppRefreshIdentifier"

    lazy public var logger: friendly_mail_core.Logger = {
        return AppleLogger()
    }()
    
    lazy public var appConfig: AppConfig = {
        let targetName = Bundle.main.infoDictionary?["CFBundleName"] as! String
        let dirName = targetName.lowercased() + "-resources"
        
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "AppConfig", ofType: "plist") ?? "")
        
        var result: AppConfig?
        
        do {
            let data = try Data.init(contentsOf: url, options: .mappedIfSafe)
            let decoder = PropertyListDecoder()
            result = try decoder.decode(AppConfig.self, from: data)
        } catch {
            print("There was an error reading app config! \(error)")
        }
        
        return result!
    }()
    
    lazy var storageProvider: AppleStorageProvider = {
        return AppleStorageProvider()
    }()
    
    lazy var settings: AppleSettings? = {
        if let existing = AppleSettings(fromUserDefaults: .standard) {
            return existing
        } else {
            return nil
            /*
            let user = Address(name: "", address: "")!
            let new = Settings()
            _ = new.save(toUserDefaults: UserDefaults.standard)
            return new
             */
        }
    }()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSS3StoragePlugin())
            try Amplify.configure()
            print("Amplify configured with Auth and Storage plugins")
        } catch {
            print("Failed to initialize Amplify with \(error)")
        }
        
        AppleSettings.addObserver(forSettings: self)
        SettingsSynchronizer.shared.synciCloud()
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: AppDelegate.backgroundAppRefreshTaskSchedulerIdentifier, using: nil) { task in
        
        }
        
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
            if let loaded = AppleSettings(fromUserDefaults: .standard) {
                self.settings = loaded
                _ = self.settings?.save(toKeyValueStore: NSUbiquitousKeyValueStore.default)
                SettingsSynchronizer.shared.synciCloud()
            }
        }
    }
}
