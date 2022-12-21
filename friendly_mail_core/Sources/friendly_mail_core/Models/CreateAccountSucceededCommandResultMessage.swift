//
//  File 2.swift
//  
//
//  Created by Philip Loden on 11/19/22.
//

import Foundation

public struct CreateAccountSucceededCommandResultMessage: AnyCommandResultMessage, BaseMessage {
    public let uidWithMailbox: UIDWithMailbox
    public let header: MessageHeader
    public let htmlBody: String?
    public let plainTextBody: String?
    public let attachments: [Attachment]?
    
    public let account: FriendlyMailAccount
    let commandResult: CommandResult
}

extension CreateAccountSucceededCommandResultMessage: Identifiable {
    public var identifier: MessageID {
        return header.messageID
    }
}
