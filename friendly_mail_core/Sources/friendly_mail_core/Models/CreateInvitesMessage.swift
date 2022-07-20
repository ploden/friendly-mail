//
//  CreateInviteMessage.swift
//  friendly-mail
//
//  Created by Philip Loden on 11/19/21.
//

import Foundation

/*
 This is the message that we send to ourselves in order to
 generate an invite to a recipient.
 */

struct CreateInvitesMessage: BaseMessage {
    let uidWithMailbox: UIDWithMailbox
    let header: MessageHeader
    let htmlBody: String?
    let plainTextBody: String?
    
    let invitees: [Address]
    let inviter: Address
    
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
    var identifier: MessageID {
        return header.messageID
    }
}
