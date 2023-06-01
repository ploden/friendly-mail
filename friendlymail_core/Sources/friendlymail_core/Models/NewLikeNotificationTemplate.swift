//
//  NewLikeNotificationTemplate.swift
//  friendlymail
//
//  Created by Philip Loden on 1/10/22.
//

import Foundation

public class NewLikeNotificationTemplate: Template {
    func populatePlainText(notification: Notification, createLikeMessage: CreateLikeMessage, createPostMessage: CreatePostingMessage) -> String? {
        if let url = plainTextTemplateURL() {
            return populate(url: url, with: [notification, createLikeMessage, createPostMessage])
        }
        return nil
    }
    
    func populateHTML(notification: Notification, createLikeMessage: CreateLikeMessage, createPostMessage: CreatePostingMessage) -> String? {
        let url = htmlTemplateURL()!
        let str = populate(url: url, with: [notification, createLikeMessage, createPostMessage])
        return str
    }

    func populateSubject(notification: Notification, createLikeMessage: CreateLikeMessage, createPostMessage: CreatePostingMessage) -> String? {
        let url = subjectTemplateURL()!
        let str = populate(url: url, with: [notification, createLikeMessage, createPostMessage])
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
                data["parentPostAuthorDisplayName"] = createPostMessage.posting.author.displayName
                data["parentPost"] = createPostMessage.posting.articleBody
                data["likePost"] = createLikeMessage.post.articleBody
            }
            
        }
        
        data["head_css_0"] = headCSS_0 ?? ""
        data["head_css_1"] = headCSS_1 ?? ""

        return data
    }
}
