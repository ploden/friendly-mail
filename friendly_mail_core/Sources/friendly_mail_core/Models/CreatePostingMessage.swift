//
//  CreatePostMessage.swift
//  friendly-mail
//
//  Created by Philip Loden on 9/9/21.
//

import Foundation

public struct CreatePostingMessage: AnyBaseMessage {
    public let uidWithMailbox: UIDWithMailbox
    public let header: MessageHeader
    public let htmlBody: String?
    public let plainTextBody: String?
    public let attachments: [Attachment]?
    
    var post: SocialMediaPosting {
        get {
            let author = Person(email: header.fromAddress.address)
            return SocialMediaPosting(author: author, dateCreated: header.date, articleBody: plainTextBody!, sharedContent: nil)
        }
    }
}

extension CreatePostingMessage: Identifiable {
    public var identifier: MessageID {
        return header.messageID
    }
}
