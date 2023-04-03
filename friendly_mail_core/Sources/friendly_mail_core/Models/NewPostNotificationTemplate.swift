//
//  NewPostNotificationTemplate.swift
//  friendly-mail
//
//  Created by Philip Loden on 11/30/21.
//

import Foundation

class NewPostNotificationTemplate: Template {
    
    func populatePartialHTML(with post: SocialMediaPosting, notification: NewPostingNotification, follow: Follow) -> String? {
        if let url = partialHTMLTemplateURL() {
            return populate(url: url, with: [post, notification, follow])
        }
        return nil
    }
    
    func populateHTML(with post: SocialMediaPosting, notification: NewPostingNotification, follow: Follow) -> String? {
        if
            let baseHTML = populateBaseHTML(),
            let partialHTML = populatePartialHTML(with: post, notification: notification, follow: follow)
        {
            let payload: [String:Any] = ["payload": partialHTML]
            let html = populate(string: baseHTML, with: payload)
            return html
        }
        return nil
    }

    func populatePlainText(with post: SocialMediaPosting, notification: NewPostingNotification, follow: Follow) -> String? {
        if let url = plainTextTemplateURL() {
            return populate(url: url, with: [post, notification, follow])
        }
        return nil
    }
    
    func populateSubject(with post: SocialMediaPosting, notification: NewPostingNotification, follow: Follow) -> String? {
        if let url = subjectTemplateURL() {
            return populate(url: url, with: [post, notification, follow])
        }
        return nil
    }
    
    override func data(with: Any) -> [String : Any] {
        var data = [String:Any]()
        
        if let withArray = with as? [Any] {
            for withFromArray in withArray {
                if let notification = withFromArray as? NewPostingNotification {
                    data["likeBody"] = "👍🏻"
                    data["createPostMessageID"] = notification.createPostingMessageID
                } else if let post = withFromArray as? SocialMediaPosting {
                    data["authorDisplayName"] = post.author.displayName
                    data["statusUpdate"] = post.articleBody
                } else if let follow = withFromArray as? Follow {
                    data["replyTo"] = follow.followee.address
                }
            }
        }
        
        if
            let replyTo = data["replyTo"],
            let createPostMessageID = data["createPostMessageID"]
        {
            let commentURL = "mailto:\(replyTo)?subject=Fm%20Comment:\(createPostMessageID)"
            data["commentURL"] = commentURL
        }

        return data
    }
}
