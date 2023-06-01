//
//  MessageHeader.swift
//  friendlymail
//
//  Created by Philip Loden on 3/11/22.
//

import Foundation
import friendlymail_core

extension MessageHeader {
    init?(host: EmailAddress, header: MCOMessageHeader, mailbox: Mailbox) {
        let to: [EmailAddress]? = header.to?.compactMap {
            if
                let mcoAddress = $0 as? MCOAddress,
                let addr = mcoAddress.mailbox
            {
                return EmailAddress(displayName: mcoAddress.displayName, address: addr)
            }
            return nil
        }
        
        guard let to = to, to.count > 0 else {
            return nil
        }
        
        let from: EmailAddress? = EmailAddress(displayName: header.from.displayName, address: header.from.mailbox)

        // Make sure we sent or received this message
        guard host.id == from?.id || to.containsIdentifiable(host) else {
            return nil
        }
                
        let replyTo: [EmailAddress] = header.replyTo?.compactMap {
            if
                let mcoAddress = $0 as? MCOAddress,
                let addr = mcoAddress.mailbox
            {
                return EmailAddress(displayName: mcoAddress.displayName, address: addr)
            }
            return nil
        } ?? [EmailAddress]()
        
        var sender: EmailAddress?
        
        if from != nil {
            if let headerSender = header.sender {
                sender = EmailAddress(displayName: headerSender.displayName, address: headerSender.mailbox)
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
            self.init(host: host,
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
