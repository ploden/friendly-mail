//
//  NewCommentNotificationTemplate.swift
//  friendly-mail
//
//  Created by Philip Loden on 12/28/21.
//

import Foundation

public class NewCommentNotificationTemplate: Template {
    
    func populatePlainText(with: NewCommentNotificationWithMessages) -> String? {
        if let url = plainTextTemplateURL() {
            return populate(url: url, with: [with.notification, with.createCommentMessage, with.createPostMessage])
        }
        return nil
    }
    
    func populateSubject(with: NewCommentNotificationWithMessages) -> String? {
        if let url = subjectTemplateURL() {
            return populate(url: url, with: [with.notification, with.createCommentMessage, with.createPostMessage])
        }
        return nil
    }
    
    override func data(with: Any) -> [String : Any] {
        var data = [String:Any]()
        
        if let withArray = with as? [Any] {
            if
                let _ = withArray.first(where: { $0 is NewCommentNotification }),
                let createCommentMessage = withArray.first(where: { $0 is CreateCommentMessage }) as? CreateCommentMessage,
                let createPostMessage = withArray.first(where: { $0 is CreatePostingMessage }) as? CreatePostingMessage
            {
                data["commentAuthorDisplayName"] = createCommentMessage.post.author.displayName
                data["parentPostAuthorDisplayName"] = createPostMessage.post.author.displayName
                data["parentPost"] = createPostMessage.post.articleBody
                data["commentPost"] = createCommentMessage.post.articleBody
                data["createCommentMessageID"] = createCommentMessage.header.messageID
                data["replyTo"] = createCommentMessage.post.author.email
                data["likeBody"] = "👍🏻"
            }
            
        }
        
        return data
    }
}
