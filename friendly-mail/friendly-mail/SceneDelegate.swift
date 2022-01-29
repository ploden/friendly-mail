//
//  SceneDelegate.swift
//  friendly-mail
//
//  Created by Philip Loden on 7/17/21.
//

import UIKit
import CocoaLumberjackSwift

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        
        let fileLogger = DDFileLogger()
        fileLogger.rollingFrequency = 60 * 60 * 24 // 24 hour rolling
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.add(fileLogger)
        
        Settings.addObserver(forSettings: self)
        
        if
            let app = UIApplication.shared.delegate as? AppDelegate,
            let windowScene = scene as? UIWindowScene
        {
            let window = UIWindow(windowScene: windowScene)
            
            let initialVC: UIViewController = {
                if app.settings.isValid,
                   let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "TabBarController") as? UITabBarController,
                   let mainMenu = vc.children.first(where: { $0 is MainMenuVC }) as? MainMenuVC
                {
                    mainMenu.mailProvider = MailProvider(settings: app.settings, messages: MessageStore())
                    return vc
                } else {
                    return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: String(describing: AddAccountVC.self))
                }
            }()
            
            let nc = UINavigationController(rootViewController: initialVC)
            
            window.rootViewController = nc
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
    }

}

extension SceneDelegate: SettingsObserver {
    func settingsDidChange(_ notification: Foundation.Notification) {
        if
            let loaded = Settings(fromUserDefaults: .standard),
            loaded.isValid,
            let nc = window?.rootViewController as? UINavigationController,
            nc.topViewController is AddAccountVC,
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "TabBarController") as? UITabBarController,
            let mainMenu = vc.children.first(where: { $0 is MainMenuVC }) as? MainMenuVC
        {
            mainMenu.mailProvider = MailProvider(settings: loaded, messages: MessageStore())
            nc.viewControllers = [vc]
        }
    }
}
