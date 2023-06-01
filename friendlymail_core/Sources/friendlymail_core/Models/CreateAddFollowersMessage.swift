//
//  CreateAddFollowersMessage.swift
//  friendlymail
//
//  Created by Philip Loden on 2/11/22.
//

import Foundation

/*
 This is the message that is sent to a person, usually
 in response to an invite, to follow to them.
 */

struct CreateAddFollowersMessage: AnyBaseMessage {
    let uidWithMailbox: UIDWithMailbox
    let header: MessageHeader
    let htmlBody: String?
    let plainTextBody: String?
    let attachments: [Attachment]?
    
    let followers: [EmailAddress]
    let followee: EmailAddress
    let frequency: UpdateFrequency
    
    var follows: [UserFollow] {
        get {
            return followers.map { UserFollow(followerID: $0.id, followeeID: followee.id, frequency: frequency, messageID: header.messageID) }
        }
    }    
}

extension CreateAddFollowersMessage: Identifiable {
    public var id: String {
        return header.messageID
    }
}
