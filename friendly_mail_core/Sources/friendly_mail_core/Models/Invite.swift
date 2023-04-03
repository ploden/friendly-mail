//
//  Invite.swift
//  friendly-mail
//
//  Created by Philip Loden on 11/19/21.
//

import Foundation

struct Invite {
    let inviter: Address
    let invitee: Address
    let createInvitesMessageID: MessageID
}

extension Invite: Equatable {
    static func ==(lhs: Invite, rhs: Invite) -> Bool {
        return lhs.inviter.id == rhs.inviter.id &&
        lhs.invitee.id == rhs.invitee.id &&
        lhs.createInvitesMessageID == rhs.createInvitesMessageID
    }
}

extension Invite: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(inviter.id)
        hasher.combine(invitee.id)
        hasher.combine(createInvitesMessageID)
    }
}

extension Invite: Codable {}
