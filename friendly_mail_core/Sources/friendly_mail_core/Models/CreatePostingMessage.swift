//
//  CreatePostMessage.swift
//  friendly-mail
//
//  Created by Philip Loden on 9/9/21.
//

import Foundation
import Stencil

public struct CreatePostingMessage: AnyBaseMessage, DynamicMemberLookup {
    public let uidWithMailbox: UIDWithMailbox
    public let header: MessageHeader
    public let htmlBody: String?
    public let plainTextBody: String?
    public let attachments: [Attachment]?
    
    var posting: SocialMediaPosting {
        get {
            let author = Person(email: header.fromAddress.address)
            return SocialMediaPosting(author: author, dateCreated: header.date, articleBody: plainTextBody!, sharedContent: nil)
        }
    }
    
    public subscript(dynamicMember member: String) -> Any? {
        if member == "posting" {
            return posting
        } else if member == "plainTextBody" {
            return plainTextBody
        } else if member == "header" {
            return header
        }
        return nil
    }
}

extension CreatePostingMessage: Identifiable {
    public var id: String {
        return header.messageID
    }
}
