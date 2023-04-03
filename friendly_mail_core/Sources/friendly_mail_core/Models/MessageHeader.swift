//
//  MessageHeader.swift
//  friendly-mail
//
//  Created by Philip Loden on 7/27/21.
//

import Foundation
import Stencil

public typealias HeaderKeyValue = (key: String, value: String)

typealias MailHeader = [HeaderKeyValue]

extension MailHeader {
    var friendlyMailMessageType: FriendlyMailMessageType? {
        get {
            if
                let messageTypeString = self.first(where: { $0.key == HeaderKey.type.rawValue })?.value,
                let messageType = FriendlyMailMessageType(rawValue: messageTypeString)
            {
                return messageType
            }
            return nil
        }
    }
}

public struct MessageHeader: DynamicMemberLookup {
    public let host: Address // the mail account that sent or received this message 
    public let fromAddress: Address
    public let toAddress: [Address]
    public let replyTo: [Address]
    public let subject: String?
    public let date: Date
    public let extraHeaders: [String : String]
    public let messageID: String
    
    var friendlyMailHeader: [HeaderKeyValue]? {
        if let str = extraHeaders["X-friendly-mail"] {
            return MessageHeader.headerKeyValues(from: str)
        }
        return nil
    }
    
    public init?(host: Address,
                 from: Address,
                 to: [Address],
                 replyTo: [Address],
                 subject: String?,
                 date: Date,
                 extraHeaders: [String : String],
                 messageID: String)
    {
        guard to.count > 0 else {
            print("TO IS EMPTY")
            return nil
        }
        self.host = host
        self.fromAddress = from
        self.toAddress = to
        self.replyTo = to
        self.subject = subject
        self.date = date
        self.extraHeaders = extraHeaders
        self.messageID = messageID
    }
    
    public subscript(dynamicMember member: String) -> Any? {
        if member == "messageID" {
            return messageID
        }
        return nil
    }
    
    static func headerKeyValues(from headerString: String) -> [HeaderKeyValue] {
        let splitted = headerString.split(separator: ";")
        var keyValues = [HeaderKeyValue]()
        for pair in splitted {
            let split_pair = pair.split(separator: "=")
            if split_pair.count == 2 {
                let k = String(split_pair[0]).trimmingCharacters(in: .whitespacesAndNewlines)
                let v = String(split_pair[1]).trimmingCharacters(in: .whitespacesAndNewlines)
                keyValues.append(HeaderKeyValue(key: k, value: v))
            }
        }
        return keyValues
    }
    
    static func headerString(from headerKeyValues: [HeaderKeyValue]) -> String {
        var pairs = [String]()
        
        for keyVal in headerKeyValues {
            pairs.append("\(keyVal.key)=\(keyVal.value)")
        }
        
        return pairs.joined(separator: "; ")
    }
}

extension MessageHeader: Codable {}

extension MessageHeader: Hashable {}
