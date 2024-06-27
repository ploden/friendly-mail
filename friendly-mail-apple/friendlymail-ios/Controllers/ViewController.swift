//
//  ViewController.swift
//  friendlymail
//
//  Created by Philip Loden on 7/30/21.
//

import Foundation
import UIKit
import CocoaLumberjackSwift

class FMViewController: UIViewController {
    
    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if let event = event, event.subtype == .motionShake {
            if let fileLogger = DDLog.allLoggers.compactMap({ $0 as? DDFileLogger }).first {
                let logFilePaths = fileLogger.logFileManager.sortedLogFilePaths
                
                var logFileDataArray = [NSData]()
                
                for logFilePath in logFilePaths {
                    let fileURL = URL(fileURLWithPath: logFilePath)
                    
                    if let logFileData = try? NSData(contentsOf: fileURL, options: NSData.ReadingOptions.mappedIfSafe) {
                        logFileDataArray.append(logFileData)
                    }
                }
                
                if
                    let mostRecentData = logFileDataArray.first,
                    let mostRecentLog = String(data: mostRecentData as Data, encoding: .utf8)
                {
                    if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: String(describing: LogVC.self)) as? LogVC {
                        vc.logText = mostRecentLog
                        present(vc, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
}
