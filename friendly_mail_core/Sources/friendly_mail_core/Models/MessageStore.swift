//
//  MessageStore.swift
//  friendly-mail
//
//  Created by Philip Loden on 1/18/22.
//

import Foundation

public struct MessageStore {
    private let messages: [MessageID : BaseMessage]
    var numMessages: Int {
        get {
            return messages.count
        }
    }
    public var allMessages: [BaseMessage] {
        get {
            return Array(messages.values)
        }
    }

    public init() {
        messages = [MessageID : BaseMessage]()
    }
    
    public init(messages: [MessageID : BaseMessage]) {
        self.messages = messages
    }
    
    func addingMessage(message: BaseMessage, messageID: MessageID) -> MessageStore {
        let messageToAdd: [MessageID : BaseMessage] = [messageID: message]
        return merging(messages: messageToAdd)
    }
    
    public func merging(messageStore: MessageStore) -> MessageStore {
        return merging(messages: messageStore.messages)
    }
    
    public func merging(messages: [MessageID : BaseMessage]) -> MessageStore {
        let mergedMessages = self.messages.merging(messages) { (old, new) in
            return old.merging(message: new)
        }
        return MessageStore(messages: mergedMessages)
    }
    
    func getMessage(for messageID: MessageID) -> BaseMessage? {
        return messages[messageID]
    }
}
