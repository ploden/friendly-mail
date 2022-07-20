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
        return lhs.inviter.identifier == rhs.inviter.identifier &&
        lhs.invitee.identifier == rhs.invitee.identifier &&
        lhs.createInvitesMessageID == rhs.createInvitesMessageID
    }
}

extension Invite: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(inviter.identifier)
        hasher.combine(invitee.identifier)
        hasher.combine(createInvitesMessageID)
    }
}

extension Invite: Codable {}
