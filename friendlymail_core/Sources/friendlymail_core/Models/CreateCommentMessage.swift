//
//  CreateCommentMessage.swift
//  friendlymail
//
//  Created by Philip Loden on 12/11/21.
//

import Foundation

public class CreateCommentMessage: BaseMessageProtocol {
    public let uidWithMailbox: UIDWithMailbox
    public let header: MessageHeader
    public let htmlBody: String?
    public let plainTextBody: String?
    public let attachments: [Attachment]?
    let posting: SocialMediaPosting
    let comment: Comment
    
    required init?(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String?, attachments: [Attachment]?) {
        guard let plainTextBody = plainTextBody, plainTextBody.count > 0 else {
            return nil
        }

        if
            let subject = header.subject,
            let parentItemMessageID = MessageFactory.extractCreateCommentAction(subject: subject)?.parentItemMessageID
        {
            self.uidWithMailbox = uidWithMailbox
            self.header = header
            self.htmlBody = htmlBody
            self.plainTextBody = plainTextBody
            let author = FriendlyMailUser(email: header.fromAddress)
            let articleBody = plainTextBody.trimmingCharacters(in: .whitespacesAndNewlines)
            self.posting = SocialMediaPosting(id: self.header.messageID, author: author, dateCreated: header.date, articleBody: articleBody, sharedContent: nil)
            self.comment = Comment(parentItemID: parentItemMessageID, createCommentID: header.messageID)
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
