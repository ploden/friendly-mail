//
//  StatusUpdate.swift
//  friendly-mail
//
//  Created by Philip Loden on 7/30/21.
//

import Foundation

public class SocialMediaPosting: Article {
    let sharedContent: [CreativeWork]?
    
    init(author: Person, dateCreated: Date, articleBody: String, sharedContent: [CreativeWork]?) {
        self.sharedContent = sharedContent
        super.init(author: author, dateCreated: dateCreated, articleBody: articleBody)
    }
    
    public override subscript(dynamicMember member: String) -> Any? {
        if member == "sharedContent" {
            return sharedContent
        }
        return super[dynamicMember: member]
    }
}

extension SocialMediaPosting: Equatable {
    public static func == (lhs: SocialMediaPosting, rhs: SocialMediaPosting) -> Bool {
        return lhs.author == rhs.author &&
        lhs.dateCreated == rhs.dateCreated &&
        lhs.articleBody == rhs.articleBody
        //lhs.sharedContent == rhs.sharedContent &&
    }
}

extension SocialMediaPosting: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(author)
        //hasher.combine(sharedContent)
        hasher.combine(dateCreated)
        hasher.combine(articleBody)
    }
}
