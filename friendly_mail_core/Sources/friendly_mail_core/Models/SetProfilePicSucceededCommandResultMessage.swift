//
//  File.swift
//  
//
//  Created by Philip Loden on 1/26/23.
//

import Foundation

public struct SetProfilePicSucceededCommandResultMessage: AnyCommandResultMessage, BaseMessage {
    public let uidWithMailbox: UIDWithMailbox
    public let header: MessageHeader
    public let htmlBody: String?
    public let plainTextBody: String?
    public let attachments: [Attachment]?
    var commandResult: CommandResult {
        get {
            return setProfilePicSucceededCommandResult
        }
    }
    public let setProfilePicSucceededCommandResult: SetProfilePicSucceededCommandResult
}

extension SetProfilePicSucceededCommandResultMessage: Identifiable {
    public var identifier: MessageID {
        return header.messageID
    }
}
