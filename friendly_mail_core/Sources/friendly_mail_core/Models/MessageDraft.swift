//
//  MessageDraft.swift
//  friendly-mail
//
//  Created by Philip Loden on 1/6/22.
//

import Foundation

public struct MessageDraft {
    public let to: [Address]
    public let subject: String
    public let htmlBody: String?
    public let plainTextBody: String
    public let friendlyMailHeaders: [HeaderKeyValue]?
}
