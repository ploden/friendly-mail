//
//  PostTemplate.swift
//  friendly-mail
//
//  Created by Philip Loden on 10/21/21.
//

import Foundation

class PostNotificationTemplate: Template {
    override func plaintTextTemplateURL() -> URL? {
        if let path = Bundle.main.path(forResource: "post_notification_template", ofType: "txt") {
            return URL(fileURLWithPath: path)
        }
        return nil
    }
    
    override func data(with: Any) -> [String : Any] {
        var data = [String:Any]()
        
        if let post = with as? Post {
            data["statusUpdate"] = post.articleBody
            data["authorDisplayName"] = post.author
        }
        
        return data
    }
    
}
