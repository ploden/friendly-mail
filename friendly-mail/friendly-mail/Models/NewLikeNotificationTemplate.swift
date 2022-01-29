//
//  NewLikeNotificationTemplate.swift
//  friendly-mail
//
//  Created by Philip Loden on 1/10/22.
//

import Foundation

class NewLikeNotificationTemplate: Template {
    override func plaintTextTemplateURL() -> URL? {
        if let path = Bundle.main.path(forResource: "new_like_notification_template", ofType: "txt") {
            return URL(fileURLWithPath: path)
        }
        return nil
    }
    
    override func subjectTemplateURL() -> URL? {
        if let path = Bundle.main.path(forResource: "new_like_notification_subject_template", ofType: "txt") {
            return URL(fileURLWithPath: path)
        }
        return nil
    }
        
    func populatePlainText(notification: Notification, createLikeMessage: CreateLikeMessage, createPostMessage: CreatePostMessage) -> String? {
        return populatePlainText(with: [notification, createLikeMessage, createPostMessage])
    }
    
    override func data(with: Any) -> [String : Any] {
        var data = [String:Any]()
        
        if let withArray = with as? [Any] {
            if
                let _ = withArray.first(where: { $0 is NewLikeNotification }),
                let createLikeMessage = withArray.first(where: { $0 is CreateLikeMessage }) as? CreateLikeMessage,
                let createPostMessage = withArray.first(where: { $0 is CreatePostMessage }) as? CreatePostMessage
            {
                data["likeAuthorDisplayName"] = createLikeMessage.post.author.name
                data["parentPostAuthorDisplayName"] = createPostMessage.post.author.name
                data["parentPost"] = createPostMessage.post.articleBody
                data["likePost"] = createLikeMessage.post.articleBody
            }
            
        }
        
        return data
    }
}
