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
    let messageID: MessageID // ID of the message that created this follow
}

extension Follow: Hashable {}

extension Follow: Codable {}

public extension Follow {
    static func == (lhs: Follow, rhs: Follow) -> Bool {
        return lhs.follower.id == rhs.follower.id &&
        lhs.followee.id == rhs.followee.id &&
        lhs.frequency == rhs.frequency &&
        lhs.messageID == rhs.messageID
    }
}

extension Follow: Identifiable {
    public var id: String {
        return messageID
    }
}
