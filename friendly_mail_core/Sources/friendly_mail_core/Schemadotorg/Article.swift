//
//  File.swift
//  
//
//  Created by Philip Loden on 4/27/22.
//

import Foundation

class Article: CreativeWork {
    let author: Person
    let dateCreated: Date
    let articleBody: String

    init(author: Person, dateCreated: Date, articleBody: String) {
        self.author = author
        self.dateCreated = dateCreated
        self.articleBody = articleBody
    }
    
}
