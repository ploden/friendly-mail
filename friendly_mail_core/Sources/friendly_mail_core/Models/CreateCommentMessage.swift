//
//  CreateCommentMessage.swift
//  friendly-mail
//
//  Created by Philip Loden on 12/11/21.
//

import Foundation

public class CreateCommentMessage: AnyBaseMessage {
    public let uidWithMailbox: UIDWithMailbox
    public let header: MessageHeader
    public let htmlBody: String?
    public let plainTextBody: String?
    public let attachments: [Attachment]?
    let post: SocialMediaPosting
    let comment: Comment
    
    required init?(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String?, attachments: [Attachment]?) {
        if
            let subject = header.subject,
            let parentItemMessageID = MessageFactory.extractMessageID(withLabel: "Comment", from: subject)
        {
            self.uidWithMailbox = uidWithMailbox
            self.header = header
            self.htmlBody = htmlBody
            self.plainTextBody = plainTextBody
            let author = Person(email: header.fromAddress.address)
            self.post = SocialMediaPosting(author: author, dateCreated: header.date, articleBody: plainTextBody!, sharedContent: nil)
            self.comment = Comment(parentItemMessageID: parentItemMessageID, createCommentMessageID: header.messageID)
            self.attachments = attachments
        } else {
            return nil
        }
    }
}

extension CreateCommentMessage: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uidWithMailbox)
    }
}
extension CreateCommentMessage: Equatable {
    public static func ==(lhs: CreateCommentMessage, rhs: CreateCommentMessage) -> Bool {
        return lhs.uidWithMailbox == rhs.uidWithMailbox &&
        lhs.header == rhs.header &&
        lhs.htmlBody == rhs.htmlBody &&
        lhs.plainTextBody == rhs.plainTextBody
    }
}

/*
extension CreateCommentMessage: Identifiable {
    public var identifier: MessageID {
        return header.messageID
    }
}
*/
