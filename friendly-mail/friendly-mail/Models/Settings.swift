//
//  Settings.swift
//  friendly-mail
//
//  Created by Philip Loden on 7/19/21.
//

import Foundation
import AppAuth

@objc protocol SettingsObserver {
    @objc func settingsDidChange(_ notification: Foundation.Notification)
}

extension Foundation.Notification.Name {
    static let settingsDidChange = Foundation.Notification.Name("FM_settingsDidChange")
}

struct Settings {
    var user: Address
    var authState: OIDAuthState?
    var password: String
    var isValid: Bool {
        if let authState = authState {
            return authState.isAuthorized && user.address.count > 0
        } else {
            return user.address.count > 0 && (password.count > 0)
        }
    }

    enum CodingKeys: String, CodingKey {
        case user
        case password
        case token
        case authState
    }
    
    public func new(withUser user: Address) -> Settings {
        var newWith = self
        newWith.user = user
        return newWith
    }

    public func new(withUser user: Address, authState: OIDAuthState) -> Settings {
        var newWith = self
        newWith.user = user
        newWith.authState = authState
        return newWith
    }
    
    public func new(withUser user: Address, password: String) -> Settings {
        var newWith = self
        newWith.user = user
        newWith.password = password
        return newWith
    }
    
    public func new(withAuthState authState: OIDAuthState) -> Settings {
        var newWith = self
        newWith.authState = authState
        return newWith
    }
    
    public func save(toUserDefaults userDefaults: UserDefaults) -> Settings? {
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
    
    public func save(toKeyValueStore keyValueStore: NSUbiquitousKeyValueStore) -> Settings? {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self) {
            keyValueStore.set(encoded, forKey: kSettingsDictionaryName)
            return self
        }
        return nil
    }
    
    static func addObserver(forSettings anObserver: SettingsObserver) {
        NotificationCenter.default.addObserver(anObserver as Any, selector: #selector(SettingsObserver.settingsDidChange(_:)), name: Foundation.Notification.Name.settingsDidChange, object: nil)
    }
    
    static func removeObserver(forSettings anObserver: SettingsObserver?) {
        NotificationCenter.default.removeObserver(anObserver as Any, name: .settingsDidChange, object: nil)
    }
}

extension Settings: Codable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        user = try values.decode(Address.self, forKey: .user)
        password = try values.decode(String.self, forKey: .password)
        
        let data = try values.decode(Data.self, forKey: .authState)
        
        if let authState = NSKeyedUnarchiver.unarchiveObject(with: data) as? OIDAuthState {
            self.authState = authState
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if let authState = self.authState {
            var data: Data? = NSKeyedArchiver.archivedData(withRootObject: authState)
            try container.encode(data, forKey: .authState)
        }

        try container.encode(user, forKey: .user)
        try container.encode(password, forKey: .password)
    }
}

extension Settings {
    public init?(fromUserDefaults userDefaults: UserDefaults) {
        if let savedSettings = userDefaults.object(forKey: kSettingsDictionaryName) as? Data {
            let decoder = JSONDecoder()
            if let loadedSettings = try? decoder.decode(Settings.self, from: savedSettings) {
                self = loadedSettings
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}
