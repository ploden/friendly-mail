//
//  MessageDraft.swift
//  friendly-mail
//
//  Created by Philip Loden on 1/6/22.
//

import Foundation

struct MessageDraft {
    let to: [Address]
    let subject: String
    let htmlBody: String?
    let plainTextBody: String
    let friendlyMailHeaders: [HeaderKeyValue]?
}
