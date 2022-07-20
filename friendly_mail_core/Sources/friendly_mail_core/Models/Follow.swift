//
//  File.swift
//  friendly-mail
//
//  Created by Philip Loden on 11/24/21.
//

import Foundation

enum SubscriptionFrequency: String, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case realtime = "realtime"
}

struct Subscription: Equatable {
    let follower: Address
    let followee: Address
    let frequency: SubscriptionFrequency
    let messageID: MessageID
}

extension Subscription: Hashable {}

extension Subscription: Codable {}

extension Subscription: Identifiable {
    var identifier: MessageID {
        return messageID
    }
}
