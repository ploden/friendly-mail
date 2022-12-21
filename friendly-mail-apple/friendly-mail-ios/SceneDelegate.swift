//
//  SceneDelegate.swift
//  friendly-mail
//
//  Created by Philip Loden on 7/17/21.
//

import UIKit
import BackgroundTasks
import friendly_mail_core

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var rootViewControllerOverride: UIViewController? {
        didSet {
            window?.rootViewController = rootViewControllerOverride
        }
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        
        AppleSettings.addObserver(forSettings: self)
        registerBackgroundTasks()

        if
            let app = UIApplication.shared.delegate as? AppDelegate,
            let windowScene = scene as? UIWindowScene
        {
            let window = UIWindow(windowScene: windowScene)
            
            let rootVC: UIViewController = {
                if let rootViewControllerOverride = rootViewControllerOverride {
                    return rootViewControllerOverride
                }
                else if
                    let settings = app.settings,
                    settings.isValid == true,
                    let tab = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "TabBarController") as? UITabBarController
                {
                    tab.delegate = self
                    let status = tab.findStatusVC()!
                    status.mailProvider = MailProvider(settings: settings, messages: MessageStore())
                    let followersFollowing = tab.findFollowingFollowersVC()!
                    followersFollowing.mailProvider = status.mailProvider
                    return tab
                } else {
                    let addAccountVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: String(describing: AddAccountVC.self))
                    return UINavigationController(rootViewController: addAccountVC)
                }
            }()
                        
            window.rootViewController = rootVC
            self.window = window
            window.makeKeyAndVisible()
        }
        
        //guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        submitBackgroundTasks()
    }

    func submitBackgroundTasks() {
        let timeDelay = 60.0
        
        do {
            let backgroundAppRefreshTaskRequest = BGAppRefreshTaskRequest(identifier: AppDelegate.backgroundAppRefreshTaskSchedulerIdentifier)
            backgroundAppRefreshTaskRequest.earliestBeginDate = Date(timeIntervalSinceNow: timeDelay)
            try BGTaskScheduler.shared.submit(backgroundAppRefreshTaskRequest)
            print("Submitted task request")
        } catch {
            print("Failed to submit BGTask")
        }
    }
    
    func registerBackgroundTasks() {
        /*
         BGTaskScheduler.shared.register(forTaskWithIdentifier: "", using: nil, launchHandler: { task in
                    
            print("BackgroundAppRefreshTaskScheduler is executed NOW!")
            print("Background time remaining: \(UIApplication.shared.backgroundTimeRemaining)s")
            
            task.expirationHandler = {
                task.setTaskCompleted(success: false)
            }
            
            // Do some data fetching and call setTaskCompleted(success:) asap!
            let isFetchingSuccess = true
            
            
            if
                let settings = self.settings,
                settings.isValid
            {
                //let mailProvider = MailProvider(settings: settings, messages: MessageStore())
                //MailController.getAndProcessAndSendMail(config: self.appConfig, sender: mailProvider, receiver: mailProvider, messages: mailProvider.messages) { _, _ in}
            }
            
            task.setTaskCompleted(success: isFetchingSuccess)
        })
         */
    }
    
}

extension SceneDelegate: SettingsObserver {
    func settingsDidChange(_ notification: Foundation.Notification) {
        if
            let loaded = AppleSettings(fromUserDefaults: .standard),
            loaded.isValid,
            let nc = window?.rootViewController as? UINavigationController,
            nc.topViewController is AddAccountVC,
            let tab = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "TabBarController") as? UITabBarController
        {
            tab.delegate = self
            let status = tab.findStatusVC()!
            status.mailProvider = MailProvider(settings: loaded, messages: MessageStore())
            
            if let followersFollowing = tab.viewControllers?.first(where: { $0 is FollowersFollowingVC }) as? FollowersFollowingVC {
                followersFollowing.mailProvider = status.mailProvider
            }
            
            nc.viewControllers = [tab]
        }
    }
}

extension SceneDelegate: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let hasMailProvider: HasMailProvider? = {
            if let vc = viewController as? HasMailProvider {
                return vc
            }
            else if
                let nc = viewController as? UINavigationController,
                let vc = nc.topViewController as? HasMailProvider
            {
                return vc
            }
            return nil
        }()
        
        if
            var hasMailProvider = hasMailProvider,
            hasMailProvider.mailProvider == nil,
            let status = tabBarController.viewControllers?.first(where: { $0 is StatusVC }) as? StatusVC,
            status.mailProvider != nil
        {
            hasMailProvider.mailProvider = status.mailProvider
        }
        return true
    }

}
