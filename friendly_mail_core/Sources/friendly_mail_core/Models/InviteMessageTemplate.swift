//
//  InviteMessageTemplate.swift
//  friendly-mail
//
//  Created by Philip Loden on 11/22/21.
//

import Foundation

class InviteMessageTemplate: Template {

    func populatePartialHTML(with invite: Invite) -> String? {
        if let url = partialHTMLTemplateURL() {
            return populate(with: invite, withURL: url)
        }
        return nil
    }
    
    func populateHTML(with invite: Invite) -> String? {
        if
            let partialHTML = populatePartialHTML(with: invite),
            let url = baseHTMLTemplateURL()
        {
            let html = populate(with: invite, withURL: url)
            let htmlWithPartial = html?.replacingOccurrences(of: "<!-- ${partial} -->", with: partialHTML)
            return htmlWithPartial
        }
        return nil
    }
    
    func populatePlainText(with invite: Invite) -> String? {
        if let url = plainTextTemplateURL() {
            return populate(with: invite, withURL: url)
        }
        return nil
    }

    func populateSubject(with invite: Invite) -> String? {
        if let url = subjectTemplateURL() {
            return populate(with: invite, withURL: url)
        }
        return nil
    }
    
    override func data(with: Any) -> [String : Any] {
        var data = [String:Any]()
        
        if let invite = with as? Invite {
            data["authorDisplayName"] = invite.inviter.name
            data["replyTo"] = invite.inviter.address
        }
        
        data["head_css"] = headCSS ?? ""
        data["footer"] = footer ?? ""
        data["header"] = header ?? ""
        
        return data
    }
}
