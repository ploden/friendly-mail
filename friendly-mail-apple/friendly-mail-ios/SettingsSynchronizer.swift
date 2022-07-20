//
//  SettingsSynchronizer.swift
//  friendly-mail
//
//  Created by Philip Loden on 7/23/21.
//

import Foundation

let kSettingsDictionaryName = "Settings"

@objc public class SettingsSynchronizer: NSObject {
  public static let shared = SettingsSynchronizer()
  
  private override init() {}
  
  public func synciCloud() {
    let store = NSUbiquitousKeyValueStore.default
    NotificationCenter.default.addObserver(self, selector: #selector(updateKVStoreItems(_:)), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: store)
    
    if store.synchronize() == false {
        //DDLogDebug("SettingsSynchronizer: synciCloud: synchronize failed")
    }
  }
  
    @objc func updateKVStoreItems(_ notification: Foundation.Notification?) {
    // Get the list of keys that changed.
    let userInfo = notification?.userInfo
    
    if let reasonForChange = userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? NSNumber {
      // Update only for changes from the server.
      let reason = reasonForChange.intValue
      
      if (reason == NSUbiquitousKeyValueStoreServerChange) || (reason == NSUbiquitousKeyValueStoreInitialSyncChange) {
        // If something is changing externally, get the changes
        // and update the corresponding keys locally.
        let changedKeys = userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [AnyHashable]
        let store = NSUbiquitousKeyValueStore.default
        let userDefaults = UserDefaults.standard
        
        // This loop assumes you are using the same key names in both
        // the user defaults database and the iCloud key-value store
        for key in changedKeys ?? [] {
          guard let key = key as? String else {
            continue
          }
          let value = store.object(forKey: key)
          userDefaults.set(value, forKey: key)
        }
        
          NotificationCenter.default.post(name: Foundation.Notification.Name.settingsDidChange, object: nil)
      }
    }
  }
}
