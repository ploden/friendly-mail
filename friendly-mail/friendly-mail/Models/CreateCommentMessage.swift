//
//  CreateCommentMessage.swift
//  friendly-mail
//
//  Created by Philip Loden on 12/11/21.
//

import Foundation

class CreateCommentMessage: BaseMessage {
    let uidWithMailbox: UIDWithMailbox
    let header: MessageHeader
    let htmlBody: String?
    let plainTextBody: String?
    let post: Post
    let comment: Comment
    
    required init?(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String?) {
        if
            let subject = header.subject,
            let parentItemMessageID = MessageFactory.extractMessageID(withLabel: "Comment", from: subject)
        {
            self.uidWithMailbox = uidWithMailbox
            self.header = header
            self.htmlBody = htmlBody
            self.plainTextBody = plainTextBody
            self.post = Post(author: header.from, articleBody: plainTextBody!, dateCreated: header.date)
            self.comment = Comment(parentItemMessageID: parentItemMessageID, createCommentMessageID: header.messageID)
        } else {
            return nil
        }
    }
}

extension CreateCommentMessage: Identifiable {
    var identifier: MessageID {
        return header.messageID
    }
}
