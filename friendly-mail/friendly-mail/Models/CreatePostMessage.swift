//
//  CreatePostMessage.swift
//  friendly-mail
//
//  Created by Philip Loden on 9/9/21.
//

import Foundation

struct CreatePostMessage: BaseMessage {
    let uidWithMailbox: UIDWithMailbox
    let header: MessageHeader
    let htmlBody: String?
    let plainTextBody: String?
    
    var post: Post {
        get {
            return Post(author: header.from, articleBody: plainTextBody!, dateCreated: header.date)
        }
    }
}

extension CreatePostMessage: Identifiable {
    var identifier: MessageID {
        return header.messageID
    }
}
