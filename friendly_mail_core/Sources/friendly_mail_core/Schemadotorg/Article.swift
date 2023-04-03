//
//  File.swift
//  
//
//  Created by Philip Loden on 4/27/22.
//

import Foundation
import Stencil

public class Article: CreativeWork, DynamicMemberLookup {
    let author: Person
    let dateCreated: Date
    let articleBody: String

    init(author: Person, dateCreated: Date, articleBody: String) {
        self.author = author
        self.dateCreated = dateCreated
        self.articleBody = articleBody
    }
    
    public subscript(dynamicMember member: String) -> Any? {
        if member == "author" {
            return author
        } else if member == "dateCreated" { 
            return dateCreated
        } else if member == "articleBody" {
            return articleBody
        }
        return nil
    }
}
