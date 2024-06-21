//
//  LikeMessage.swift
//  friendlymail
//
//  Created by Philip Loden on 9/9/21.
//

import Foundation
import Stencil

public class CreateLikeMessage: BaseMessageProtocol {
    public let uidWithMailbox: UIDWithMailbox
    public let header: MessageHeader
    public let htmlBody: String?
    public let plainTextBody: String?
    public let attachments: [Attachment]?
    let post: SocialMediaPosting
    let like: Like

    required init?(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String?, attachments: [Attachment]?) {
        guard let plainTextBody = plainTextBody, plainTextBody.count > 0 else {
            return nil
        }
        
        if
            let subject = header.subject,
            let parentItemMessageID = MessageFactory.extractMessageID(withLabel: "Like", from: subject)
        {
            self.uidWithMailbox = uidWithMailbox
            self.header = header
            self.htmlBody = htmlBody
            self.plainTextBody = plainTextBody
            let author = FriendlyMailUser(email: header.fromAddress)
            let articleBody = plainTextBody.trimmingCharacters(in: .whitespacesAndNewlines)
            self.post = SocialMediaPosting(id: header.messageID, author: author, dateCreated: header.date, articleBody: articleBody, sharedContent: nil)
            self.like = Like(parentItemMessageID: parentItemMessageID, createLikeMessageID: header.messageID)
            self.attachments = attachments
        } else {
            return nil
        }
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
