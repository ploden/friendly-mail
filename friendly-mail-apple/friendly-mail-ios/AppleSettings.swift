//
//  Settings.swift
//  friendly-mail
//
//  Created by Philip Loden on 3/12/22.
//

import Foundation
import friendly_mail_core
import AppAuth

public struct AppleSettings: Settings {
    public var user: Address
    public var authState: OIDAuthState?
    public var password: String?
    public var isValid: Bool {
        if let authState = authState {
            return authState.isAuthorized && user.address.count > 0
        } else {
            return user.address.count > 0 && (password != nil)
        }
    }

    enum CodingKeys: String, CodingKey {
        case user
        case password
        case token
        case authState
        case selectedTheme
    }
    
    public init(user: Address, selectedTheme: Theme) {
        self.user = user
        //self.selectedTheme = selectedTheme
    }
    
    public func new(withUser user: Address) -> AppleSettings {
        var newWith = self
        newWith.user = user
        return newWith
    }

    public func new(withUser user: Address, authState: OIDAuthState) -> AppleSettings {
        var newWith = self
        newWith.user = user
        newWith.authState = authState
        return newWith
    }
    
    public func new(withUser user: Address, password: String) -> AppleSettings {
        var newWith = self
        newWith.user = user
        newWith.password = password
        return newWith
    }
    
    public func new(withAuthState authState: OIDAuthState) -> AppleSettings {
        var newWith = self
        newWith.authState = authState
        return newWith
    }
    
    public func new(withSelectedTheme selectedTheme: Theme) -> AppleSettings {
        var newWith = self
        //newWith.selectedTheme = selectedTheme
        return newWith
    }
    
    public static func addObserver(forSettings anObserver: SettingsObserver) {
        NotificationCenter.default.addObserver(anObserver as Any, selector: #selector(SettingsObserver.settingsDidChange(_:)), name: Foundation.Notification.Name.settingsDidChange, object: nil)
    }
    
    static func removeObserver(forSettings anObserver: SettingsObserver?) {
        NotificationCenter.default.removeObserver(anObserver as Any, name: .settingsDidChange, object: nil)
    }
}

extension AppleSettings: Codable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        user = try values.decode(Address.self, forKey: .user)
        //selectedTheme = try values.decode(Theme.self, forKey: .selectedTheme)
        password = try? values.decode(String.self, forKey: .password)

        let data = try values.decode(Data.self, forKey: .authState)
        
        if let authState = NSKeyedUnarchiver.unarchiveObject(with: data) as? OIDAuthState {
            self.authState = authState
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if let authState = self.authState {
            var data: Data? = NSKeyedArchiver.archivedData(withRootObject: authState)
            try container.encode(data, forKey: .authState)
        }

        try container.encode(user, forKey: .user)
        try container.encode(password, forKey: .password)
        //try container.encode(selectedTheme, forKey: .selectedTheme)
    }
}

extension AppleSettings {
    
    public func save(toUserDefaults userDefaults: UserDefaults) -> AppleSettings? {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self) {
            userDefaults.set(encoded, forKey: kSettingsDictionaryName)
            OperationQueue.main.addOperation({
                NotificationCenter.default.post(name: Foundation.Notification.Name.settingsDidChange, object: nil)
            })
            return self
        }
        return nil
    }

    public func save(toKeyValueStore keyValueStore: NSUbiquitousKeyValueStore) -> AppleSettings? {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self) {
            keyValueStore.set(encoded, forKey: kSettingsDictionaryName)
            return self
        }
        return nil
    }
    
}

public extension AppleSettings {
    init?(fromUserDefaults userDefaults: UserDefaults) {
        if let savedSettings = userDefaults.object(forKey: kSettingsDictionaryName) as? Data {
            let decoder = JSONDecoder()
            if let loaded = try? decoder.decode(AppleSettings.self, from: savedSettings) {
                self = loaded
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}
