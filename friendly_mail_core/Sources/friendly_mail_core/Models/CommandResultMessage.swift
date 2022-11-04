//
//  CommandResultMessage.swift
//  
//
//  Created by Philip Loden on 11/3/22.
//

import Foundation

struct CommandResultMessage {
    let uidWithMailbox: UIDWithMailbox
    let messageID: MessageID
    let header: MessageHeader
    let htmlBody: String?
    let plainTextBody: String?
    let attachments: [Attachment]?
    
    let commandMessageID: MessageID
    let commandResult: CommandResult
}
