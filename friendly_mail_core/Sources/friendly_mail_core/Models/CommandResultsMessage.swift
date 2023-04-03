//
//  CommandResultMessage.swift
//  
//
//  Created by Philip Loden on 11/3/22.
//

import Foundation

public struct CommandResultsMessage: AnyCommandResultsMessage, AnyBaseMessage {
    public let uidWithMailbox: UIDWithMailbox
    public let header: MessageHeader
    public let htmlBody: String?
    public let plainTextBody: String?
    public let attachments: [Attachment]?
    
    public let commandResults: [CommandResult]
}

extension CommandResultsMessage: Identifiable {
    public var id: String {
        return header.messageID
    }
}
