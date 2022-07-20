//
//  NewLikeNotificationPartial.swift
//  friendly-mail
//
//  Created by Philip Loden on 2/25/22.
//

import Foundation

class NewLikeNotificationPartial: Template {
    override func htmlTemplateURL() -> URL? {
        if let path = Bundle.main.path(forResource: "new_like_notification_partial_working", ofType: "html", inDirectory: "\(theme.directory)/html") {
            return URL(fileURLWithPath: path)
        }
        return nil
    }

    func populatePlainText(notification: Notification, createLikeMessage: CreateLikeMessage, createPostMessage: CreatePostingMessage) -> String? {
        if let url = plainTextTemplateURL() {
            return populate(with: [notification, createLikeMessage, createPostMessage], withURL: url)
        }
        return nil
    }
    
    func populateHTML(with createLikeMessage: CreateLikeMessage, createPostMessage: CreatePostingMessage) -> String? {
        if let url = htmlTemplateURL() {
            let str = populate(with: [createLikeMessage, createPostMessage], withURL: url)
            return str
        }
        return nil
    }
    
    override func data(with: Any) -> [String : Any] {
        var data = [String:Any]()
        
        if let withArray = with as? [Any] {
            if
                let _ = withArray.first(where: { $0 is NewLikeNotification }),
                let createLikeMessage = withArray.first(where: { $0 is CreateLikeMessage }) as? CreateLikeMessage,
                let createPostMessage = withArray.first(where: { $0 is CreatePostingMessage }) as? CreatePostingMessage
            {
                data["likeAuthorDisplayName"] = createLikeMessage.post.author.displayName
                data["parentPostAuthorDisplayName"] = createPostMessage.post.author.displayName
                data["parentPost"] = createPostMessage.post.articleBody
                data["likePost"] = createLikeMessage.post.articleBody
            }
            
        }
        
        return data
    }
}
