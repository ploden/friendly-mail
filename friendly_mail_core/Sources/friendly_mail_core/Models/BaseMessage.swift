//
//  BaseMessage.swift
//  friendly-mail
//
//  Created by Philip Loden on 12/7/21.
//

import Foundation

public protocol BaseMessage: Identifiable {
    var uidWithMailbox: UIDWithMailbox { get }
    var header: MessageHeader { get }
    var htmlBody: String? { get }
    var plainTextBody: String? { get }
    var attachments: [Attachment]? { get }
    var shouldFetch: Bool { get }
    func merging(message: BaseMessage) -> BaseMessage
}

extension BaseMessage {
    public var shouldFetch: Bool {
        return plainTextBody == nil /* || htmlBody == nil */
    }
}

extension BaseMessage {
    public func merging(message: BaseMessage) -> BaseMessage {
        if self is Message && (message is Message) == false {
            return message
        } else if type(of: self) == type(of: message) {
            return self.plainTextBody != nil ? self : message
        } else {
            return self
        }
    }
}

extension BaseMessage {
    public func isFriendlyMailMessage() -> Bool {
        return MessageFactory.isFriendlyMailMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
    }
}
