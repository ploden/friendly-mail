//
//  MessageDraft.swift
//  friendlymail
//
//  Created by Philip Loden on 1/6/22.
//

import Foundation

public struct MessageDraft: MessageDraftProtocol {
    public let to: [EmailAddress]
    public let subject: String
    public let htmlBody: String?
    public let plainTextBody: String
    public let friendlyMailHeaders: [HeaderKeyValue]?
}
