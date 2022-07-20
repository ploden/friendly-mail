//
//  Message.swift
//  friendly-mail
//
//  Created by Philip Loden on 7/30/21.
//

import Foundation

public struct Message: BaseMessage {
    public let uidWithMailbox: UIDWithMailbox
    public let header: MessageHeader
    public let htmlBody: String?
    public let plainTextBody: String?
    
    public static func headers() {
        
    }
    
    public init(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String?) {
        self.uidWithMailbox = uidWithMailbox
        self.header = header
        self.htmlBody = htmlBody
        self.plainTextBody = plainTextBody
    }
}

extension Message: Hashable {}

extension Message: Codable {}

extension Message: Identifiable {
    public var identifier: MessageID {
        return header.messageID
    }
}
