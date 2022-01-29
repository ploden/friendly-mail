//
//  Message.swift
//  friendly-mail
//
//  Created by Philip Loden on 7/30/21.
//

import Foundation

struct Message: BaseMessage {    
    let uidWithMailbox: UIDWithMailbox
    let header: MessageHeader
    let htmlBody: String?
    let plainTextBody: String?
    
    static func headers() {
        
    }
}

extension Message: Hashable {}

extension Message: Codable {}

extension Message: Identifiable {
    var identifier: MessageID {
        return header.messageID
    }
}
