//
//  Identifiable.swift
//  friendly-mail
//
//  Created by Philip Loden on 8/19/21.
//

import Foundation

typealias MailboxName = String

extension MailboxName {
    static let friendlyMail = "friendly-mail"
    static let sent = "[Gmail]/Sent Mail"
}

struct Mailbox: Hashable, Codable {
    let name: MailboxName
    let UIDValidity: UInt32
}

struct UIDWithMailbox: Hashable {
    let UID: UInt64
    let mailbox: Mailbox
}

typealias MessageID = String

extension UIDWithMailbox: Codable {}

protocol Identifiable {
    var identifier: MessageID { get }
}
