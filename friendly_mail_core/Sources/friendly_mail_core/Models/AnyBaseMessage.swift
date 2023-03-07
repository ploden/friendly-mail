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

/*
extension AnyBaseMessage {
    public func compare(_ lhs: any AnyBaseMessage, _ rhs: any AnyBaseMessage) -> ComparisonResult {
        return lhs.header.date.compare(rhs.header.date)
    }
}
*/

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
