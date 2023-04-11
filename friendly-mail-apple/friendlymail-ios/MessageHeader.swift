//
//  MessageHeader.swift
//  friendlymail
//
//  Created by Philip Loden on 3/11/22.
//

import Foundation
import friendlymail_core

extension MessageHeader {
    init?(host: Address, header: MCOMessageHeader, mailbox: Mailbox) {
        let to: [Address]? = header.to?.compactMap {
            if
                let mcoAddress = $0 as? MCOAddress,
                let addr = mcoAddress.mailbox
            {
                return Address(name: mcoAddress.displayName, address: addr, isHost: addr == host.id)
            }
            return nil
        }
        
        guard let to = to, to.count > 0 else {
            return nil
        }
        
        let from: Address? = Address(name: header.from.displayName, address: header.from.mailbox, isHost: header.from.mailbox == host.id)

        // Make sure we sent or received this message
        guard host.id == from?.id || to.containsIdentifiable(host) else {
            return nil
        }
                
        let replyTo: [Address] = header.replyTo?.compactMap {
            if
                let mcoAddress = $0 as? MCOAddress,
                let addr = mcoAddress.mailbox
            {
                return Address(name: mcoAddress.displayName, address: addr, isHost: addr == host.id)
            }
            return nil
        } ?? [Address]()
        
        var sender: Address?
        
        if from != nil {
            if let headerSender = header.sender {
                sender = Address(name: headerSender.displayName, address: headerSender.mailbox, isHost: headerSender.mailbox == host.id)
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
