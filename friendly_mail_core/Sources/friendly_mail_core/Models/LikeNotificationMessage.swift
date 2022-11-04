//
//  LikeNotificationMessage.swift
//  friendly-mail
//
//  Created by Philip Loden on 9/9/21.
//

import Foundation

struct LikeNotificationMessage: BaseMessage {
    let uidWithMailbox: UIDWithMailbox
    let messageID: MessageID
    let header: MessageHeader
    let htmlBody: String?
    let plainTextBody: String?
    let attachments: [Attachment]?
    
    let originalContentID: MessageID
    let likeMessageID: MessageID
}

extension LikeNotificationMessage: Identifiable {
    var identifier: MessageID {
        return header.messageID
    }
}
