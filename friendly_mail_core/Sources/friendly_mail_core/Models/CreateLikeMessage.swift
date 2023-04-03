//
//  LikeMessage.swift
//  friendly-mail
//
//  Created by Philip Loden on 9/9/21.
//

import Foundation
import Stencil

public class CreateLikeMessage: AnyBaseMessage, DynamicMemberLookup {
    public let uidWithMailbox: UIDWithMailbox
    public let header: MessageHeader
    public let htmlBody: String?
    public let plainTextBody: String?
    public let attachments: [Attachment]?
    let post: SocialMediaPosting
    let like: Like

    required init?(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String?, attachments: [Attachment]?) {
        if
            let subject = header.subject,
            let parentItemMessageID = MessageFactory.extractMessageID(withLabel: "Like", from: subject)
        {
            self.uidWithMailbox = uidWithMailbox
            self.header = header
            self.htmlBody = htmlBody
            self.plainTextBody = plainTextBody
            let author = Person(email: header.fromAddress.address)
            self.post = SocialMediaPosting(author: author, dateCreated: header.date, articleBody: plainTextBody!, sharedContent: nil)
            self.like = Like(parentItemMessageID: parentItemMessageID, createLikeMessageID: header.messageID)
            self.attachments = attachments
        } else {
            return nil
        }
    }
    
    public subscript(dynamicMember member: String) -> Any? {
        if member == "like" {
            return like
        } else if member == "post" {
            return post
        }
        return nil
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(post)
        hasher.combine(like)
    }
}

public extension CreateLikeMessage {
    static func == (lhs: CreateLikeMessage, rhs: CreateLikeMessage) -> Bool {
        return lhs.post == rhs.post &&
        lhs.like == rhs.like
    }
}

extension CreateLikeMessage: Identifiable {
    public var identifier: MessageID {
        return header.messageID
    }
}
