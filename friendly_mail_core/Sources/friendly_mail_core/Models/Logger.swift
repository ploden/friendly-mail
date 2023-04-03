//
//  Logger.swift
//  
//
//  Created by Philip Loden on 12/10/22.
//

import Foundation

public protocol Logger {
    func log(message: String)
    func log(message: String, level: LogLevel)
}
