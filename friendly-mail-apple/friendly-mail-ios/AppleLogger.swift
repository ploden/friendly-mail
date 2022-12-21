//
//  AppleLogger.swift
//  friendly-mail-ios
//
//  Created by Philip Loden on 12/10/22.
//

import Foundation
import CocoaLumberjackSwift
import friendly_mail_core

struct AppleLogger: Logger {
    func log(message: String) {
#if targetEnvironment(simulator)
        print(message)
#endif
        DDLogDebug(message)
    }
    
    public init() {
        let fileLogger = DDFileLogger()
        fileLogger.rollingFrequency = 60 * 60 * 24 // 24 hour rolling
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.add(fileLogger)
    }
    
}
