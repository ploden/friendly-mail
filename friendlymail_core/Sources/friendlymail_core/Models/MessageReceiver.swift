//
//  MessageSource.swift
//  friendlymail
//
//  Created by Philip Loden on 11/16/21.
//

import Foundation
//import MailCore

public enum HeaderName: String {
    case friendlymail = "X-friendlymail"
}

public protocol MessageReceiver {
    func downloadFriendlyMailMessages(completion: @escaping (Error?, MessageStore?) -> ())
    func getMail(withMailbox mailbox: Mailbox, completion: @escaping (Error?, MessageStore?) -> ())
    func fetchMessage(uidWithMailbox: UIDWithMailbox, completion: @escaping (Error?, (any AnyBaseMessage)?) -> ())
    func fetchFriendlyMailMessage(messageID: MessageID, completion: @escaping (Error?, (any AnyBaseMessage)?) -> ())
    var address: EmailAddress { get }
}

public protocol MessageSender {
    func sendDraft(draft: AnyMessageDraft) async throws -> MessageID
    func sendMessage(to: [EmailAddress], subject: String?, htmlBody: String?, plainTextBody: String, friendlyMailHeaders: [HeaderKeyValue]?, logger: Logger?, completion: @escaping (Result<MessageID, Error>) -> Void)
    func moveMessageToInbox(message: any AnyBaseMessage, completion: @escaping (Error?) -> ())
}
