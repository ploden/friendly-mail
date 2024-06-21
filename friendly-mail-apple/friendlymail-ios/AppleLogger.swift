//
//  AppleLogger.swift
//  friendlymail-ios
//
//  Created by Philip Loden on 12/10/22.
//

import Foundation
import CocoaLumberjackSwift
import friendlymail_core

struct AppleLogger: friendlymail_core.Logger {
    func log(message: String, level: friendlymail_core.LogLevel) {
#if targetEnvironment(simulator)
        let filter: String? = "getAndProcessAndSendMail"
        
        if
            let filter = filter,
            message.contains(filter)
        {
            print(message)
        }
#endif
        DDLogDebug(message)
    }
    
    func log(message: String) {
        log(message: message, level: .debug)
    }
    
    public init() {
        let fileLogger = DDFileLogger()
        fileLogger.rollingFrequency = 60 * 60 * 24 // 24 hour rolling
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.add(fileLogger)
    }
    
}
