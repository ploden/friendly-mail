//
//  Follow.swift
//  friendly-mail
//
//  Created by Philip Loden on 11/24/21.
//

import Foundation

enum UpdateFrequency: String, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case realtime = "realtime"
    case undefined = "undefined"
}

public struct Follow: Equatable {
    let follower: Address
    let followee: Address
    let frequency: UpdateFrequency
    let messageID: MessageID
}

extension Follow: Hashable {}

extension Follow: Codable {}

extension Follow: Identifiable {
    public var identifier: MessageID {
        return messageID
    }
}
