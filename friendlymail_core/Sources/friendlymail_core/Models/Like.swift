//
//  Like.swift
//  friendlymail
//
//  Created by Philip Loden on 8/19/21.
//

import Foundation

struct Like: Hashable {
    let parentItemMessageID: MessageID // messageID of create post message of parent
    let createLikeMessageID: MessageID // messageID of create like message
}
