//
//  UpdateFollowerMessage.swift
//  friendly-mail
//
//  Created by Philip Loden on 11/26/21.
//

import Foundation

/*
 This is the message that is sent to a follower
 that contains the content the followee has created.
 */

struct NotificationsMessage: AnyBaseMessage {
    let uidWithMailbox: UIDWithMailbox
    let header: MessageHeader
    let htmlBody: String?
    let plainTextBody: String?
    let attachments: [Attachment]?
    let notifications: [Notification]
}

extension NotificationsMessage: Identifiable {
    public var id: String {
        return header.messageID
    }
}
