//
//  BaseMessage.swift
//  friendlymail
//
//  Created by Philip Loden on 12/7/21.
//

import Foundation

public protocol BaseMessageProtocol: Identifiable {
    var uidWithMailbox: UIDWithMailbox { get }
    var header: MessageHeader { get }
    var htmlBody: String? { get }
    var plainTextBody: String? { get }
    var attachments: [Attachment]? { get }
    var shouldFetch: Bool { get }
    func merging(message: any BaseMessageProtocol) -> any BaseMessageProtocol
}

extension BaseMessageProtocol {
    public var shouldFetch: Bool {
        return plainTextBody == nil
    }
}

extension BaseMessageProtocol {
    public func merging(message: any BaseMessageProtocol) -> any BaseMessageProtocol {
        if self is Message && (message is Message) == false {
            return message
        } else if type(of: self) == type(of: message) {
            return self.plainTextBody != nil ? self : message
        } else {
            return self
        }
    }
}

extension BaseMessageProtocol {
    public func isFriendlyMailMessage() -> Bool {
        return MessageFactory.isFriendlyMailMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
    }
}

extension BaseMessageProtocol {
    public var id: MessageID {
        get {
            return header.messageID
        }
    }
}

extension BaseMessageProtocol {
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
