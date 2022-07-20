//
//  NewLikeNotificationTemplate.swift
//  friendly-mail
//
//  Created by Philip Loden on 1/10/22.
//

import Foundation

public class NewLikeNotificationTemplate: Template {
    func populatePlainText(notification: Notification, createLikeMessage: CreateLikeMessage, createPostMessage: CreatePostingMessage) -> String? {
        if let url = plainTextTemplateURL() {
            return populate(with: [notification, createLikeMessage, createPostMessage], withURL: url)
        }
        return nil
    }
    
    func populateHTML(notification: Notification, createLikeMessage: CreateLikeMessage, createPostMessage: CreatePostingMessage) -> String? {
        let url = htmlTemplateURL()!
        let str = populate(with: [notification, createLikeMessage, createPostMessage], withURL: url)
        return str
    }

    func populateSubject(notification: Notification, createLikeMessage: CreateLikeMessage, createPostMessage: CreatePostingMessage) -> String? {
        let url = subjectTemplateURL()!
        let str = populate(with: [notification, createLikeMessage, createPostMessage], withURL: url)
        return str
    }
    
    override func data(with: Any) -> [String : Any] {
        var data = [String:Any]()
        
        if let withArray = with as? [Any] {
            if
                let createLikeMessage = withArray.first(where: { $0 is CreateLikeMessage }) as? CreateLikeMessage,
                let createPostMessage = withArray.first(where: { $0 is CreatePostingMessage }) as? CreatePostingMessage
            {
                data["likeAuthorDisplayName"] = createLikeMessage.post.author.displayName
                data["parentPostAuthorDisplayName"] = createPostMessage.post.author.displayName
                data["parentPost"] = createPostMessage.post.articleBody
                data["likePost"] = createLikeMessage.post.articleBody
            }
            
        }
        
        data["head_css"] = headCSS ?? ""

        return data
    }
}
