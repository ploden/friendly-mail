//
//  CreateInviteMessage.swift
//  friendlymail
//
//  Created by Philip Loden on 11/19/21.
//

import Foundation

/*
 This is the message that we send to ourselves in order to
 generate an invite to a recipient.
 */

struct CreateInvitesMessage: BaseMessageProtocol {
    let uidWithMailbox: UIDWithMailbox
    let header: MessageHeader
    let htmlBody: String?
    let plainTextBody: String?
    let attachments: [Attachment]?
    
    let invitees: [EmailAddress]
    let inviter: EmailAddress
    
    var invites: [Invite] {
        get {
            return invitees.map { Invite(inviter: inviter, invitee: $0, createInvitesMessageID: self.header.messageID) }
        }
    }
}

extension CreateInvitesMessage: Hashable {}
extension CreateInvitesMessage: Equatable {}
extension CreateInvitesMessage: Codable {}

extension CreateInvitesMessage: Identifiable {
    public var id: String {
        return header.messageID
    }
}
