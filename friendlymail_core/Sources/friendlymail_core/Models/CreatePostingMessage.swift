//
//  CreatePostMessage.swift
//  friendlymail
//
//  Created by Philip Loden on 9/9/21.
//

import Foundation
import Stencil

public struct CreatePostingMessage: BaseMessageProtocol {
    public let uidWithMailbox: UIDWithMailbox
    public let header: MessageHeader
    public let htmlBody: String?
    public let plainTextBody: String?
    public let attachments: [Attachment]?
    
    var posting: SocialMediaPosting {
        get {
            let author = FriendlyMailUser(email: header.fromAddress)
            let articleBody = plainTextBody!.trimmingCharacters(in: .whitespacesAndNewlines)
            return SocialMediaPosting(id: self.id, author: author, dateCreated: header.date, articleBody: articleBody, sharedContent: nil)
        }
    }
}

extension CreatePostingMessage: Identifiable {
    public var id: String {
        return header.messageID
    }
}
