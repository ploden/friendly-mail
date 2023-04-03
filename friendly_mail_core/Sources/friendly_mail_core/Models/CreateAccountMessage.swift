//
//  File 2.swift
//  
//
//  Created by Philip Loden on 11/14/22.
//

import Foundation

/*
 This is the message that we send to ourselves in order to
 create a friendly-mail account.
 */

public struct CreateAccountMessage: AnyBaseMessage {
    public let uidWithMailbox: UIDWithMailbox
    public let header: MessageHeader
    public let htmlBody: String?
    public let plainTextBody: String?
    public let attachments: [Attachment]?
}

extension CreateAccountMessage: Hashable {}
extension CreateAccountMessage: Equatable {}
extension CreateAccountMessage: Codable {}

extension CreateAccountMessage: Identifiable {
    public var id: String {
        return header.messageID
    }
}
