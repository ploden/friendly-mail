//
//  BaseMessage.swift
//  friendly-mail
//
//  Created by Philip Loden on 12/7/21.
//

import Foundation

public protocol AnyBaseMessage: Identifiable {
    var uidWithMailbox: UIDWithMailbox { get }
    var header: MessageHeader { get }
    var htmlBody: String? { get }
    var plainTextBody: String? { get }
    var attachments: [Attachment]? { get }
    var shouldFetch: Bool { get }
    func merging(message: any AnyBaseMessage) -> any AnyBaseMessage
}

extension AnyBaseMessage {
    public var shouldFetch: Bool {
        return plainTextBody == nil /* || htmlBody == nil */
    }
}

extension AnyBaseMessage {
    public func merging(message: any AnyBaseMessage) -> any AnyBaseMessage {
        if self is Message && (message is Message) == false {
            return message
        } else if type(of: self) == type(of: message) {
            return self.plainTextBody != nil ? self : message
        } else {
            return self
        }
    }
}

extension AnyBaseMessage {
    public func isFriendlyMailMessage() -> Bool {
        return MessageFactory.isFriendlyMailMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
    }
}

extension AnyBaseMessage {
    public var id: MessageID {
        get {
            return header.messageID
        }
    }
}

extension AnyBaseMessage {
    var shortDescription: String {
        let shortBody = self.plainTextBody!.replacingOccurrences(of: "\n", with: " ").prefix(100)
        
        let desc =
        """
From: \(self.header.fromAddress.address)
To: \(self.header.toAddress.first!.address)
Subject: \(self.header.subject ?? "")
\(shortBody)
"""
        return desc
    }
}
