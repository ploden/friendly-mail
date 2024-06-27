//
//  Settings.swift
//  friendlymail
//
//  Created by Philip Loden on 7/19/21.
//

import Foundation
import AuthenticationServices

@objc public protocol SettingsObserver {
    @objc func settingsDidChange(_ notification: Foundation.Notification)
}

extension Foundation.Notification.Name {
    public static let settingsDidChange = Foundation.Notification.Name("FM_settingsDidChange")
}

public protocol AuthStateDelegate: Codable {
    func isAuthorized() -> Bool
    func performAction(freshTokens: (String?, String?, Error?) -> ())
}

public protocol Settings {
    //var selectedTheme: Theme { get set }
    var isValid: Bool { get }
}
