//
//  MessageSource.swift
//  friendly-mail
//
//  Created by Philip Loden on 11/16/21.
//

import Foundation
import MailCore
import CocoaLumberjackSwift

enum HeaderName: String {
    case friendlymail = "X-friendly-mail"
}

protocol MessageReceiver {
    func getMail(withMailbox mailbox: Mailbox, completion: @escaping (Error?, MessageStore?) -> ())
    func fetchMessage(uidWithMailbox: UIDWithMailbox, completion: @escaping (Error?, BaseMessage?) -> ())
    func fetchFriendlyMailMessage(messageID: MessageID, completion: @escaping (Error?, BaseMessage?) -> ())
}

protocol MessageSender {
    func sendMessage(to: [Address], subject: String?, htmlBody: String?, plainTextBody: String, friendlyMailHeaders: [HeaderKeyValue]?, completion: @escaping (Error?, MessageID?) -> ())
    func moveMessageToInbox(message: BaseMessage, completion: @escaping (Error?) -> ())
}
