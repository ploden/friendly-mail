//
//  NewPostNotificationTemplate.swift
//  friendly-mail
//
//  Created by Philip Loden on 11/30/21.
//

import Foundation

class NewPostNotificationTemplate: Template {
    override func plaintTextTemplateURL() -> URL? {
        if let path = Bundle.main.path(forResource: "new_post_notification_template", ofType: "txt") {
            return URL(fileURLWithPath: path)
        }
        return nil
    }
    
    override func subjectTemplateURL() -> URL? {
        if let path = Bundle.main.path(forResource: "new_post_notification_subject_template", ofType: "txt") {
            return URL(fileURLWithPath: path)
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
                } else if let post = withFromArray as? Post {
                    data["authorDisplayName"] = post.author.name
                    data["statusUpdate"] = post.articleBody
                } else if let subscription = withFromArray as? Subscription {
                    data["replyTo"] = subscription.followee.address
                }
            }
        }
        
        return data
    }
}
