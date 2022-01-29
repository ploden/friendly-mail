//
//  InviteMessageTemplate.swift
//  friendly-mail
//
//  Created by Philip Loden on 11/22/21.
//

import Foundation

class InviteMessageTemplate: Template {
    override func plaintTextTemplateURL() -> URL? {
        if let path = Bundle.main.path(forResource: "invite_template", ofType: "txt") {
            return URL(fileURLWithPath: path)
        }
        return nil
    }
    
    override func subjectTemplateURL() -> URL? {
        if let path = Bundle.main.path(forResource: "invite_subject_template", ofType: "txt") {
            return URL(fileURLWithPath: path)
        }
        return nil
    }
    
    override func data(with: Any) -> [String : Any] {
        var data = [String:Any]()
        
        if let invite = with as? Invite {
            data["authorDisplayName"] = invite.inviter.name
            data["replyTo"] = invite.inviter.address
        }
        
        return data
    }
}
