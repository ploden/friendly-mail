//
//  Comment.swift
//  friendlymail
//
//  Created by Philip Loden on 12/11/21.
//

import Foundation

public struct Comment {
    let parentItemID: ID // messageID of create post message of parent
    let createCommentID: ID // messageID of create comment message
}

extension Comment: Equatable {}
