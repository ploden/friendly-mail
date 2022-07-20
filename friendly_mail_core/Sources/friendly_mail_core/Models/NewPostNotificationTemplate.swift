//
//  NewPostNotificationTemplate.swift
//  friendly-mail
//
//  Created by Philip Loden on 11/30/21.
//

import Foundation

class NewPostNotificationTemplate: Template {
    
    func populatePartialHTML(with post: SocialMediaPosting, notification: NewPostNotification, subscription: Subscription) -> String? {
        if let url = partialHTMLTemplateURL() {
            return populate(with: [post, notification, subscription], withURL: url)
        }
        return nil
    }
    
    func populateHTML(with post: SocialMediaPosting, notification: NewPostNotification, subscription: Subscription) -> String? {
        if
            let partialHTML = populatePartialHTML(with: post, notification: notification, subscription: subscription),
            let url = baseHTMLTemplateURL()
        {
            let html = populate(with: [post, notification, subscription], withURL: url)
            let htmlWithPartial = html?.replacingOccurrences(of: "${partial}", with: partialHTML)
            return htmlWithPartial
        }
        return nil
    }

    func populatePlainText(with post: SocialMediaPosting, notification: NewPostNotification, subscription: Subscription) -> String? {
        if let url = plainTextTemplateURL() {
            return populate(with: [post, notification, subscription], withURL: url)
        }
        return nil
    }
    
    func populateSubject(with post: SocialMediaPosting, notification: NewPostNotification, subscription: Subscription) -> String? {
        if let url = subjectTemplateURL() {
            return populate(with: [post, notification, subscription], withURL: url)
        }
        return nil
    }
    
    override func data(with: Any) -> [String : Any] {
        var data = [String:Any]()
        
        if let withArray = with as? [Any] {
            for withFromArray in withArray {
                if let notification = withFromArray as? NewPostNotification {
                    data["likeBody"] = "👍🏻"
                    data["createPostMessageID"] = notification.createPostMessageID
                } else if let post = withFromArray as? SocialMediaPosting {
                    data["authorDisplayName"] = post.author.displayName
                    data["statusUpdate"] = post.articleBody
                } else if let subscription = withFromArray as? Subscription {
                    data["replyTo"] = subscription.followee.address
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
        
        data["head_css"] = headCSS ?? ""
        data["footer"] = footer ?? ""
        data["header"] = header ?? ""

        return data
    }
}
