//
//  LikeMessage.swift
//  friendly-mail
//
//  Created by Philip Loden on 9/9/21.
//

import Foundation

public class CreateLikeMessage: BaseMessage {
    public let uidWithMailbox: UIDWithMailbox
    public let header: MessageHeader
    public let htmlBody: String?
    public let plainTextBody: String?
    let post: SocialMediaPosting
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
            let author = Person(email: header.fromAddress.address)
            self.post = SocialMediaPosting(author: author, dateCreated: header.date, articleBody: plainTextBody!, sharedContent: nil)
            self.like = Like(parentItemMessageID: parentItemMessageID, createLikeMessageID: header.messageID)
        } else {
            return nil
        }
    }
}

extension CreateLikeMessage: Identifiable {
    public var identifier: MessageID {
        return header.messageID
    }
}
