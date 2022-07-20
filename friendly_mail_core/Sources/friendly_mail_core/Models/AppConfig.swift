//
//  AppConfig.swift
//  friendly-mail
//
//  Created by Philip Loden on 2/11/22.
//

import Foundation

public struct AppConfig: Decodable {
    let copyright: String
    public let defaultThemeName: String
    public let themes: [Theme]
    public var defaultTheme: Theme {
        get {
            return themes.first(where: { $0.name.lowercased() == defaultThemeName.lowercased() })!
        }
    }
}
