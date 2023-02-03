//
//  AddFollowersSucceededCommandResultMessage.swift
//  
//
//  Created by Philip Loden on 1/28/23.
//

import Foundation

public struct AddFollowersSucceededCommandResultMessage: AnyCommandResultMessage, BaseMessage {
    public let uidWithMailbox: UIDWithMailbox
    public let header: MessageHeader
    public let htmlBody: String?
    public let plainTextBody: String?
    public let attachments: [Attachment]?
    var commandResult: CommandResult {
        get {
            return addFollowersSucceededCommandResult
        }
    }
    public let addFollowersSucceededCommandResult: AddFollowersSucceededCommandResult
}

extension AddFollowersSucceededCommandResultMessage: Identifiable {
    public var identifier: MessageID {
        return header.messageID
    }
}
