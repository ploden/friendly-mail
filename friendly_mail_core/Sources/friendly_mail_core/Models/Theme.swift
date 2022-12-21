//
//  Theme.swift
//  friendly-mail
//
//  Created by Philip Loden on 2/11/22.
//

import Foundation

public struct Theme: Equatable {
    public let name: String
    let directory: String
}

extension Theme: Codable {}

extension Theme: Identifiable {
    public var identifier: MessageID {
        return name
    }
}
