//
//  LikeMessage.swift
//  friendly-mail
//
//  Created by Philip Loden on 9/9/21.
//

import Foundation

class CreateLikeMessage: BaseMessage {
    let uidWithMailbox: UIDWithMailbox
    let header: MessageHeader
    let htmlBody: String?
    let plainTextBody: String?
    let post: Post
    let like: Like
    
    required init?(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String?) {
        if
            let subject = header.subject,
            let parentItemMessageID = MessageFactory.extractMessageID(withLabel: "Like", from: subject)
        {
            self.uidWithMailbox = uidWithMailbox
            self.header = header
            self.htmlBody = htmlBody
            self.plainTextBody = plainTextBody
            self.post = Post(author: header.from, articleBody: plainTextBody!, dateCreated: header.date)
            self.like = Like(parentItemMessageID: parentItemMessageID, createLikeMessageID: header.messageID)
        } else {
            return nil
        }
    }
}

extension CreateLikeMessage: Identifiable {
    var identifier: MessageID {
        return header.messageID
    }
}
