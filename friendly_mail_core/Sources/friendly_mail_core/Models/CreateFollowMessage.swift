//
//  CreateFollowMessage.swift
//  friendly-mail
//
//  Created by Philip Loden on 11/24/21.
//

import Foundation

/*
 This is the message that is sent to a person, usually
 in response to an invite, to follow to them.
 */

struct CreateFollowMessage: AnyBaseMessage {
    let uidWithMailbox: UIDWithMailbox
    let header: MessageHeader
    let htmlBody: String?
    let plainTextBody: String?
    let attachments: [Attachment]?
    
    let follower: Address
    let followee: Address
    let frequency: UpdateFrequency
    
    var subscription: Follow {
        get {
            return Follow(follower: follower, followee: followee, frequency: frequency, messageID: header.messageID)
        }
    }
}

extension CreateFollowMessage: Identifiable {
    public var id: String {
        return header.messageID
    }
}
