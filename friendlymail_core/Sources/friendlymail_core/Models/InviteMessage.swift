//
//  InviteMessage.swift
//  friendlymail
//
//  Created by Philip Loden on 11/19/21.
//

import Foundation

/*
 This message is sent to the invitee.
 */
struct InviteMessage: BaseMessageProtocol {    
    let uidWithMailbox: UIDWithMailbox
    let header: MessageHeader
    let htmlBody: String?
    let plainTextBody: String?
    let attachments: [Attachment]?
    let invite: Invite
}

extension InviteMessage: Identifiable {
    public var id: String {
        return header.messageID
    }
}
