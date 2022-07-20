//
//  CreateAddFollowersMessage.swift
//  friendly-mail
//
//  Created by Philip Loden on 2/11/22.
//

import Foundation

/*
 This is the message that is sent to a person, usually
 in response to an invite, to follow to them.
 */

struct CreateAddFollowersMessage: BaseMessage {
    let uidWithMailbox: UIDWithMailbox
    let header: MessageHeader
    let htmlBody: String?
    let plainTextBody: String?
    
    let followers: [Address]
    let followee: Address
    let frequency: SubscriptionFrequency
    
    var subscriptions: [Subscription] {
        get {
            return followers.map { Subscription(follower: $0, followee: followee, frequency: frequency, messageID: header.messageID) }
        }
    }
}

extension CreateAddFollowersMessage: Identifiable {
    var identifier: MessageID {
        return header.messageID
    }
}
