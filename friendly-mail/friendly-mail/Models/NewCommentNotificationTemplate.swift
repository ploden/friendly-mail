//
//  NewCommentNotificationTemplate.swift
//  friendly-mail
//
//  Created by Philip Loden on 12/28/21.
//

import Foundation

class NewCommentNotificationTemplate: Template {
    override func plaintTextTemplateURL() -> URL? {
        if let path = Bundle.main.path(forResource: "new_comment_notification_template", ofType: "txt") {
            return URL(fileURLWithPath: path)
        }
        return nil
    }
    
    override func subjectTemplateURL() -> URL? {
        if let path = Bundle.main.path(forResource: "new_comment_notification_template", ofType: "txt") {
            return URL(fileURLWithPath: path)
        }
        return nil
    }
    
     func populatePlainText(with: NewCommentNotificationWithMessages) -> String? {
        return populatePlainText(with: [with.notification, with.createCommentMessage, with.createPostMessage])
    }
    
    override func data(with: Any) -> [String : Any] {
        var data = [String:Any]()
        
        if let withArray = with as? [Any] {
            if
                let _ = withArray.first(where: { $0 is NewCommentNotification }),
                let createCommentMessage = withArray.first(where: { $0 is CreateCommentMessage }) as? CreateCommentMessage,
                let createPostMessage = withArray.first(where: { $0 is CreatePostMessage }) as? CreatePostMessage
            {
                data["commentAuthorDisplayName"] = createCommentMessage.post.author.name
                data["parentPostAuthorDisplayName"] = createPostMessage.post.author.name
                data["parentPost"] = createPostMessage.post.articleBody
                data["commentPost"] = createCommentMessage.post.articleBody
                data["createCommentMessageID"] = createCommentMessage.header.messageID
                data["replyTo"] = createCommentMessage.post.author.address
                data["likeBody"] = "👍🏻"
            }
            
        }
        
        return data
    }
}
