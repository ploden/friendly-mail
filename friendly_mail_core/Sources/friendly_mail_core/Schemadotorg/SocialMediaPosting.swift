//
//  StatusUpdate.swift
//  friendly-mail
//
//  Created by Philip Loden on 7/30/21.
//

import Foundation

class SocialMediaPosting: Article {
    let sharedContent: [CreativeWork]?
    
    init(author: Person, dateCreated: Date, articleBody: String, sharedContent: [CreativeWork]?) {
        self.sharedContent = sharedContent
        super.init(author: author, dateCreated: dateCreated, articleBody: articleBody)
    }
}

extension SocialMediaPosting: Equatable {
    static func == (lhs: SocialMediaPosting, rhs: SocialMediaPosting) -> Bool {
        return false
    }
}

extension SocialMediaPosting: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(author)
    }
}
