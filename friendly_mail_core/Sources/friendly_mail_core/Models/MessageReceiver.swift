//
//  MessageSource.swift
//  friendly-mail
//
//  Created by Philip Loden on 11/16/21.
//

import Foundation
//import MailCore

public enum HeaderName: String {
    case friendlymail = "X-friendly-mail"
}

public protocol MessageReceiver {
    func downloadFriendlyMailMessages(completion: @escaping (Error?, MessageStore?) -> ())
    func getMail(withMailbox mailbox: Mailbox, completion: @escaping (Error?, MessageStore?) -> ())
    func fetchMessage(uidWithMailbox: UIDWithMailbox, completion: @escaping (Error?, BaseMessage?) -> ())
    func fetchFriendlyMailMessage(messageID: MessageID, completion: @escaping (Error?, BaseMessage?) -> ())
    var address: Address { get }
}

public protocol MessageSender {
    func sendDraft(draft: MessageDraft) async throws -> MessageID
    @available(*, deprecated, renamed: "sendDraft")
    func sendDraft(draft: MessageDraft, completion: @escaping (Result<MessageID, Error>) -> Void)
    func sendMessage(to: [Address], subject: String?, htmlBody: String?, plainTextBody: String, friendlyMailHeaders: [HeaderKeyValue]?, completion: @escaping (Result<MessageID, Error>) -> Void)
    func moveMessageToInbox(message: BaseMessage, completion: @escaping (Error?) -> ())
}
