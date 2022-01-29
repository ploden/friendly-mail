//
//  MessageHeader.swift
//  friendly-mail
//
//  Created by Philip Loden on 7/27/21.
//

import Foundation
import MailCore

typealias HeaderKeyValue = (key: String, value: String)

struct MessageHeader {
    let sender: Address?
    let from: Address
    let to: [Address]
    let replyTo: [Address]
    let subject: String?
    let date: Date
    let extraHeaders: [String : String]
        
    var friendlyMailHeader: [HeaderKeyValue]? {
        if let str = extraHeaders["X-friendly-mail"] {
            return MessageHeader.headerKeyValues(from: str)
        }
        return nil
    }
        
    let messageID: String
    
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

extension MessageHeader {
    init?(header: MCOMessageHeader, mailbox: Mailbox) {
        let to: [Address] = header.to.compactMap {
            if
                let mcoAddress = $0 as? MCOAddress,
                let addr = mcoAddress.mailbox
            {
                return Address(name: mcoAddress.displayName, address: addr)
            }
            return nil
        }
        let replyTo: [Address] = header.replyTo?.compactMap {
            if
                let mcoAddress = $0 as? MCOAddress,
                let addr = mcoAddress.mailbox
            {
                return Address(name: mcoAddress.displayName, address: addr)
            }
            return nil
        } ?? [Address]()
        
        if let from = Address(name: header.from.displayName, address: header.from.mailbox) {
            if let headerSender = header.sender {
                self.sender = Address(name: headerSender.displayName, address: headerSender.mailbox)
            } else {
                self.sender = nil
            }
            self.from = from
            self.to = to
            self.replyTo = replyTo
            self.subject = header.subject
            self.date = header.date
        } else {
            return nil
        }
        
        var extra = [String:String]()
        header.allExtraHeadersNames().forEach {
            if
                let name = $0 as? String,
                let val = header.extraHeaderValue(forName: name)
            {
                extra[name] = val
            }
        }
        extraHeaders = extra
        messageID = header.messageID
    }
}

extension MessageHeader: Codable {}

extension MessageHeader: Hashable {}
