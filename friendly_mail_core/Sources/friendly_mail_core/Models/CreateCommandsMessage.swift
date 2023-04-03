//
//  CreateCommandMessage.swift
//  
//
//  Created by Philip Loden on 10/19/22.
//

import Foundation

/*
 This is the message that is used to update user settings.
 */

struct CreateCommandsMessage: AnyBaseMessage {
    let uidWithMailbox: UIDWithMailbox
    let header: MessageHeader
    let htmlBody: String?
    let plainTextBody: String?
    let attachments: [Attachment]?
    let commands: [Command]
    
    static var commandPrefix = "Fm: "
}

extension CreateCommandsMessage: Identifiable {
    public var id: String {
        return header.messageID
    }
}
