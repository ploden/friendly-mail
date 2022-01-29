//
//  LikeNotificationTemplate.swift
//  friendly-mail
//
//  Created by Philip Loden on 10/22/21.
//

import Foundation

class LikeNotificationTemplate: Template {
    override func plaintTextTemplateURL() -> URL? {
        if let path = Bundle.main.path(forResource: "like_notification_template", ofType: "txt") {
            return URL(fileURLWithPath: path)
        }
        return nil
    }
    
    override func data(with: Any) -> [String : Any] {
        let data = [String:Any]()
        
        if let withArray = with as? [Any] {
            for withFromArray in withArray {
                if let _ = withFromArray as? Like {
                    //data["authorDisplayName"] = like.authorDisplayName
                } else if let _ = withFromArray as? Post {

                }
            }
        }
        
        return data
    }
}
