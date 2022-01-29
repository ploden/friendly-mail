//
//  StatusUpdate.swift
//  friendly-mail
//
//  Created by Philip Loden on 7/30/21.
//

import Foundation

struct Post: Equatable {
    let author: Address
    let articleBody: String
    let dateCreated: Date
}

extension Post: Hashable {}

extension Post: Codable {}
