//
//  Identifiable.swift
//  friendly-mail
//
//  Created by Philip Loden on 8/19/21.
//

import Foundation

public typealias MailboxName = String

public extension MailboxName {
    static let friendlyMail = "friendly-mail"
    static let sent = "[Gmail]/Sent Mail"
}

public struct Mailbox: Hashable, Codable {
    public let name: MailboxName
    public let UIDValidity: UInt32
    
    public init(name: MailboxName, UIDValidity: UInt32) {
        self.name = name
        self.UIDValidity = UIDValidity
    }
}

public struct UIDWithMailbox: Hashable {
    public let UID: UInt64
    public let mailbox: Mailbox
    
    public init(UID: UInt64, mailbox: Mailbox) {
        self.UID = UID
        self.mailbox = mailbox
    }
}

public typealias ID = String

public typealias PersonID = ID

public typealias MessageID = ID

extension UIDWithMailbox: Codable {}

public protocol Identifiable {
    var identifier: ID { get }
}
