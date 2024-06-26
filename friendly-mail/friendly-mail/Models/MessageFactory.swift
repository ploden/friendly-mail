//
//  MessageFactory.swift
//  friendly-mail
//
//  Created by Philip Loden on 8/23/21.
//

import Foundation
import os

enum FriendlyMailMessageType: String {
    case invite = "invite"
    case notifications = "notifications"
}

struct MessageFactory {
    
    static func logMessage(logger: Logger, typeName: String, from: String, to: String, subject: String, plainTextBody: String) {
        let shortSubject = String(subject.prefix(10))
        let shortBody = String(plainTextBody.prefix(10))
        logger.log("MessageFactory: CREATING \(typeName). from: \(from) to: \(to) subject: \(shortSubject) body: \(shortBody)")
    }
    
    static func createMessage(settings: Settings, uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String?) -> BaseMessage? {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "misc")

        if MessageFactory.isFriendlyMailMessage(settings: settings, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody) {
            if let plainTextBody = plainTextBody {
                if
                    MessageFactory.isCreateInviteMessage(settings: settings, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
                    let invitees = MessageFactory.extractInvitees(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
                    invitees.count > 0
                {
                    MessageFactory.logMessage(logger: logger, typeName: "CreateInvitesMessage", from: header.from.address, to: header.to.first?.address ?? "", subject: header.subject ?? "", plainTextBody: plainTextBody)
                    return CreateInvitesMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, invitees: invitees, inviter: header.from)
                }
                else if
                    MessageFactory.isInviteMessage(settings: settings, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
                    let createInvitesMessageID = header.friendlyMailHeader?.first(where: { $0.key == HeaderKey.createInvitesMessageID.rawValue })?.value
                {
                    MessageFactory.logMessage(logger: logger, typeName: "InviteMessage", from: header.from.address, to: header.to.first?.address ?? "", subject: header.subject ?? "", plainTextBody: plainTextBody)
                    let invite = Invite(inviter: header.from, invitee: header.to.first!, createInvitesMessageID: createInvitesMessageID)
                    return InviteMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, invite: invite)
                }
                else if
                    MessageFactory.isCreatePostMessage(settings: settings, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
                {
                    MessageFactory.logMessage(logger: logger, typeName: "CreatePostMessage", from: header.from.address, to: header.to.first?.address ?? "", subject: header.subject ?? "", plainTextBody: plainTextBody)
                    return CreatePostMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
                }
                else if
                    MessageFactory.isCreateSubscriptionMessage(settings: settings, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
                    let frequency = MessageFactory.extractSubscriptionFrequency(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
                    let followee = header.to.first
                {
                    MessageFactory.logMessage(logger: logger, typeName: "CreateSubscriptionMessage", from: header.from.address, to: header.to.first?.address ?? "", subject: header.subject ?? "", plainTextBody: plainTextBody)
                    return CreateSubscriptionMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, follower: header.from, followee: followee, frequency: frequency)
                }
                else if
                    MessageFactory.isNotificationsMessage(settings: settings, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
                    let notifications = MessageFactory.extractNotifications(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
                {
                    MessageFactory.logMessage(logger: logger, typeName: "NotificationsMessage", from: header.from.address, to: header.to.first?.address ?? "", subject: header.subject ?? "", plainTextBody: plainTextBody)
                    return NotificationsMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, notifications: notifications)
                }
                else if
                    MessageFactory.isCreateCommentMessage(settings: settings, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
                {
                    MessageFactory.logMessage(logger: logger, typeName: "CreateCommentMessage", from: header.from.address, to: header.to.first?.address ?? "", subject: header.subject ?? "", plainTextBody: plainTextBody)
                    return CreateCommentMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
                }
                else if
                    MessageFactory.isCreateLikeMessage(settings: settings, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
                {
                    MessageFactory.logMessage(logger: logger, typeName: "CreateLikeMessage", from: header.from.address, to: header.to.first?.address ?? "", subject: header.subject ?? "", plainTextBody: plainTextBody)
                    return CreateLikeMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
                }
            }
        }
        MessageFactory.logMessage(logger: logger, typeName: "Message", from: header.from.address, to: header.to.first?.address ?? "", subject: header.subject ?? "", plainTextBody: plainTextBody ?? "")
        return Message(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
    }

    static func isInviteMessage(settings: Settings, uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String?) -> Bool {
        if
            let messageType = header.friendlyMailHeader?.first(where: { $0.key == HeaderKey.type.rawValue })?.value,
            messageType == FriendlyMailMessageType.invite.rawValue
        {
            return true
        }
        return false
    }

    static func isFriendlyMailMessage(settings: Settings, uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String?) -> Bool {
        if header.extraHeaders.keys.contains(HeaderName.friendlymail.rawValue) {
            return true
        } else if isFMSubject(subject: header.subject) {
            return true
        }
        return false
    }
    
    static func isFMSubject(subject: String?) -> Bool {
        if
            let subject = subject,
            subject.count >= 14,
            subject[..<subject.index(subject.startIndex, offsetBy: 14)] == "friendly-mail:"
        {
            return true
        } else if
            let subject = subject,
            subject.count >= 2,
            subject[..<subject.index(subject.startIndex, offsetBy: 2)] == "Fm" || subject[..<subject.index(subject.startIndex, offsetBy: 2)] == "fm"
        {
            return true
        } else {
            return false
        }
    }
    
    static func isCreateInviteMessage(settings: Settings, uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String) -> Bool {
        if header.from.address == settings.user.address {
            let splitted = plainTextBody.components(separatedBy: .whitespaces)
            
            if
                splitted.count > 1,
                let first = splitted.first,
                first == "Invite" || first == "invite"
            {
                let possibleAddresses = splitted[1..<splitted.count]
                return possibleAddresses.map { $0.isValidEmail() }.reduce(false) { $0 || $1 }
            }
        }
        
        return false
    }

    static func isCreateSubscriptionMessage(settings: Settings, uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String) -> Bool {
        let splitted = plainTextBody.components(separatedBy: .whitespaces)
        
        if
            splitted.count > 1,
            let first = splitted.first,
            first == "Follow" || first == "follow"
        {
            let frequency = MessageFactory.extractSubscriptionFrequency(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
            return frequency != nil
        }
        
        return false
    }

    static func extractSubscriptionFrequency(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String) -> SubscriptionFrequency? {
        let splitted = plainTextBody.components(separatedBy: .whitespaces)
        
        if
            splitted.count > 1,
            let first = splitted.first,
            first == "Follow" || first == "follow"
        {
            let possibleFrequency = splitted[1]
            return SubscriptionFrequency(rawValue: possibleFrequency.lowercased())
        }
        return nil
    }
    
    static func extractInvitees(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String) -> [Address]? {
        let splitted = plainTextBody.components(separatedBy: .whitespaces)
        
        if
            splitted.count > 1,
            let first = splitted.first,
            first == "Invite" || first == "invite"
        {
            let possibleAddresses = splitted[1..<splitted.count]
            let validAddresses = possibleAddresses.filter { $0.isValidEmail() }
            return validAddresses.compactMap { Address(name: "", address: $0) }
        }
        
        return nil
    }
    
    static func isCreatePostMessage(settings: Settings, uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String) -> Bool {
        if
            header.friendlyMailHeader == nil,
            settings.user.address == header.from.address,
            let to = header.to.first,
            to.address == settings.user.address
        {
            return true
        }
        return false
    }

    static func isCreateCommentMessage(settings: Settings, uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String) -> Bool {
        if
            MessageFactory.isFriendlyMailMessage(settings: settings, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
            let subject = header.subject,
            subject.contains("Comment:")
        {
            return true
        }
        return false
    }
    
    static func isCreateLikeMessage(settings: Settings, uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String) -> Bool {
        if
            MessageFactory.isFriendlyMailMessage(settings: settings, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
            let subject = header.subject,
            subject.contains("Like:")
        {
            return true
        }
        return false
    }
    
    static func isNotificationsMessage(settings: Settings, uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String?) -> Bool {
        if
            let messageType = header.friendlyMailHeader?.first(where: { $0.key == HeaderKey.type.rawValue })?.value,
            messageType == FriendlyMailMessageType.notifications.rawValue
        {
            return true
        }
        return false
    }
    
    static func extractNotifications(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String) -> [Notification]? {
        let notifications: [Notification]? = header.friendlyMailHeader?.compactMap {
            if let headerKey = HeaderKey(rawValue: $0.key) {
                switch headerKey {
                case .type:
                    return nil
                case .notificationCreateCommentMessageID:
                    return NewCommentNotification(createCommentMessageID: $0.value)
                case .notificationCreatePostMessageID:
                    return NewPostNotification(createPostMessageID: $0.value)
                case .notificationCreateLikeMessageID:
                    return NewLikeNotification(createLikeMessageID: $0.value)
                case .createInvitesMessageID:
                    return nil
                }
            }
            return nil
        }
        return notifications
    }
    
    static func extractMessageID(withLabel label: String, from: String) -> String? {
        if
            let pair = from.split(separator: " ").first(where: { $0.split(separator: ":").first ?? "" == label} )?.split(separator: ":"),
            pair.count > 1
        {
            return String(pair[1])
        }
        return nil
    }
}
