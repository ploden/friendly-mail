//
//  LikeNotificationTemplate.swift
//  friendly-mail
//
//  Created by Philip Loden on 10/22/21.
//

import Foundation

class LikeNotificationTemplate: Template {
    
    override func data(with: Any) -> [String : Any] {
        let data = [String:Any]()
        
        if let withArray = with as? [Any] {
            for withFromArray in withArray {
                if let _ = withFromArray as? Like {
                    //data["authorDisplayName"] = like.authorDisplayName
                } else if let _ = withFromArray as? SocialMediaPosting {

                }
            }
        }
        
        return data
    }
}
