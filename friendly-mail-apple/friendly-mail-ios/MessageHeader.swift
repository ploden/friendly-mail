//
//  MessageHeader.swift
//  friendly-mail
//
//  Created by Philip Loden on 3/11/22.
//

import Foundation
import friendly_mail_core

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
        
        let from: Address? = Address(name: header.from.displayName, address: header.from.mailbox)
        var sender: Address?
        
        if from != nil {
            if let headerSender = header.sender {
                sender = Address(name: headerSender.displayName, address: headerSender.mailbox)
            }
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
        
        if let from = from {
            self.init(sender: sender,
                      from: from,
                      to: to,
                      replyTo: replyTo,
                      subject: header.subject,
                      date: header.date,
                      extraHeaders: extra,
                      messageID: header.messageID)
        } else {
            return nil
        }
    }
}
