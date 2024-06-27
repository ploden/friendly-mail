//
//  InviteMessageTemplate.swift
//  friendlymail
//
//  Created by Philip Loden on 11/22/21.
//

import Foundation

class InviteMessageTemplate: Template {

    func populatePartialHTML(with invite: Invite) -> String? {
        if let url = partialHTMLTemplateURL() {
            return populate(url: url, with: invite)
        }
        return nil
    }
    
    func populateHTML(with invite: Invite) -> String? {
        if
            let baseHTML = populateBaseHTML()
        {
            return baseHTML
        }
        /*
        if
            //let partialHTML = populatePartialHTML(with: invite),
            let url = baseHTMLTemplateURL()
        {
            let html = populate(url: url, with: invite)
            //let htmlWithPartial = html?.replacingOccurrences(of: "<!-- ${partial} -->", with: partialHTML)
            return html
        }
         */
        return nil
    }
    
    func populatePlainText(with invite: Invite) -> String? {
        if let url = plainTextTemplateURL() {
            return populate(url: url, with: invite)
        }
        return nil
    }

    func populateSubject(with invite: Invite) -> String? {
        if let url = subjectTemplateURL() {
            return populate(url: url, with: invite)
        }
        return nil
    }
    
    override func data(with: Any) -> [String : Any] {
        var data = [String:Any]()
        
        if let invite = with as? Invite {
            data["authorDisplayName"] = invite.inviter.displayName
            data["replyTo"] = invite.inviter.address
        }
        
        //data["head_css_0"] = headCSS_0 ?? ""
        //data["head_css_1"] = headCSS_1 ?? ""
        //data["footer"] = footer ?? ""
        //data["header"] = header ?? ""
        
        return data
    }
}
