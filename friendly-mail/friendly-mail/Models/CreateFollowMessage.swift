//
//  CreateSubscriptionMessage.swift
//  friendly-mail
//
//  Created by Philip Loden on 11/24/21.
//

import Foundation

/*
 This is the message that is sent to a person, usually
 in response to an invite, to follow to them.
 */

struct CreateSubscriptionMessage: BaseMessage {
    let uidWithMailbox: UIDWithMailbox
    let header: MessageHeader
    let htmlBody: String?
    let plainTextBody: String?
    
    let follower: Address
    let followee: Address
    let frequency: SubscriptionFrequency
    
    var subscription: Subscription {
        get {
            return Subscription(follower: follower, followee: followee, frequency: frequency, messageID: header.messageID)
        }
    }
}

extension CreateSubscriptionMessage: Identifiable {
    var identifier: MessageID {
        return header.messageID
    }
}
