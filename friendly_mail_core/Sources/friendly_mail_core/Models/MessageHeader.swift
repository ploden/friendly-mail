//
//  MessageHeader.swift
//  friendly-mail
//
//  Created by Philip Loden on 7/27/21.
//

import Foundation

public typealias HeaderKeyValue = (key: String, value: String)

public struct MessageHeader {
    public let sender: Address?
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
    
    public init?(sender: Address?,
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
        self.sender = sender
        self.fromAddress = from
        self.toAddress = to
        self.replyTo = to
        self.subject = subject
        self.date = date
        self.extraHeaders = extraHeaders
        self.messageID = messageID
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
