//
//  MessageFactory.swift
//  friendly-mail
//
//  Created by Philip Loden on 8/23/21.
//

import Foundation
//import os

enum FriendlyMailMessageType: String {
    case invite = "invite"
    case notifications = "notifications"
}

public struct MessageFactory {
    
    /*
    static func logMessage(logger: Logger, typeName: String, from: String, to: String, subject: String, plainTextBody: String) {
        let shortSubject = String(subject.prefix(10))
        let shortBody = String(plainTextBody.prefix(10))
        logger.log("MessageFactory: CREATING \(typeName). from: \(from) to: \(to) subject: \(shortSubject) body: \(shortBody)")
    }
     */
    
    public static func createMessage(settings: Settings,
                                     uidWithMailbox: UIDWithMailbox,
                                     header: MessageHeader,
                                     htmlBody: String?,
                                     plainTextBody: String?,
                                     attachments: [Attachment]?) -> BaseMessage? {
        //let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "misc")

        if MessageFactory.isFriendlyMailMessage(settings: settings, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody) {
            if let plainTextBody = plainTextBody {
                if
                    MessageFactory.isCreateCommandMessage(settings: settings, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
                    let commands = MessageFactory.extractCommands(messageID: header.messageID, htmlBody: htmlBody, plainTextBody: plainTextBody),
                    commands.count > 0
                {
                    return CreateCommandsMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments, commands: commands)
                }
                else if
                    MessageFactory.isCreateInviteMessage(settings: settings, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
                    let invitees = MessageFactory.extractInvitees(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
                    invitees.count > 0
                {
                    //MessageFactory.logMessage(logger: logger, typeName: "CreateInvitesMessage", from: header.from.address, to: header.to.first?.address ?? "", subject: header.subject ?? "", plainTextBody: plainTextBody)
                    return CreateInvitesMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments, invitees: invitees, inviter: header.fromAddress)
                }
                else if
                    MessageFactory.isCreateAddFollowersMessage(settings: settings, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
                    let followersToAdd = MessageFactory.extractFollowersToAdd(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
                    let followee = header.toAddress.first
                {
                    //MessageFactory.logMessage(logger: logger, typeName: "CreateAddFollowersMessage", from: header.from.address, to: header.to.first?.address ?? "", subject: header.subject ?? "", plainTextBody: plainTextBody)
                    return CreateAddFollowersMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments, followers: followersToAdd, followee: followee, frequency: .realtime)
                }
                else if
                    MessageFactory.isInviteMessage(settings: settings, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
                    let createInvitesMessageID = header.friendlyMailHeader?.first(where: { $0.key == HeaderKey.createInvitesMessageID.rawValue })?.value
                {
                    //MessageFactory.logMessage(logger: logger, typeName: "InviteMessage", from: header.from.address, to: header.to.first?.address ?? "", subject: header.subject ?? "", plainTextBody: plainTextBody)
                    let invite = Invite(inviter: header.fromAddress, invitee: header.toAddress.first!, createInvitesMessageID: createInvitesMessageID)
                    return InviteMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments, invite: invite)
                }
                else if
                    MessageFactory.isCreatePostMessage(settings: settings, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
                {
                    //MessageFactory.logMessage(logger: logger, typeName: "CreatePostMessage", from: header.from.address, to: header.to.first?.address ?? "", subject: header.subject ?? "", plainTextBody: plainTextBody)
                    return CreatePostingMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments)
                }
                else if
                    MessageFactory.isCreateSubscriptionMessage(settings: settings, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
                    let frequency = MessageFactory.extractSubscriptionFrequency(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
                    let followee = header.toAddress.first
                {
                    //MessageFactory.logMessage(logger: logger, typeName: "CreateSubscriptionMessage", from: header.from.address, to: header.to.first?.address ?? "", subject: header.subject ?? "", plainTextBody: plainTextBody)
                    return CreateSubscriptionMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments, follower: header.fromAddress, followee: followee, frequency: frequency)
                }
                else if
                    MessageFactory.isNotificationsMessage(settings: settings, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
                    let notifications = MessageFactory.extractNotifications(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
                {
                    //MessageFactory.logMessage(logger: logger, typeName: "NotificationsMessage", from: header.from.address, to: header.to.first?.address ?? "", subject: header.subject ?? "", plainTextBody: plainTextBody)
                    return NotificationsMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments, notifications: notifications)
                }
                else if
                    MessageFactory.isCreateCommentMessage(settings: settings, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
                {
                    //MessageFactory.logMessage(logger: logger, typeName: "CreateCommentMessage", from: header.from.address, to: header.to.first?.address ?? "", subject: header.subject ?? "", plainTextBody: plainTextBody)
                    return CreateCommentMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments)
                }
                else if
                    MessageFactory.isCreateLikeMessage(settings: settings, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
                {
                    //MessageFactory.logMessage(logger: logger, typeName: "CreateLikeMessage", from: header.from.address, to: header.to.first?.address ?? "", subject: header.subject ?? "", plainTextBody: plainTextBody)
                    return CreateLikeMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments)
                }
            }
        }
        //MessageFactory.logMessage(logger: logger, typeName: "Message", from: header.from.address, to: header.to.first?.address ?? "", subject: header.subject ?? "", plainTextBody: plainTextBody ?? "")
        return Message(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments)
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
    
    static func isCreateAddFollowersMessage(settings: Settings, uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String) -> Bool {
        if header.fromAddress.address == settings.user.address {
            let splitted = plainTextBody.components(separatedBy: .whitespaces)
            
            if
                splitted.count > 1,
                let first = splitted.first,
                first == "Add" || first == "add"
            {
                let possibleAddresses = splitted[1..<splitted.count]
                return possibleAddresses.map { $0.isValidEmail() }.reduce(false) { $0 || $1 }
            }
        }
        
        return false
    }
    
    static func isCreateInviteMessage(settings: Settings, uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String) -> Bool {
        if header.fromAddress.address == settings.user.address {
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

    static func extractCommands(messageID: MessageID, htmlBody: String?, plainTextBody: String) -> [Command]? {
        let splitted = plainTextBody.components(separatedBy: .newlines)
        
        if let first = splitted.first {
            let splittedFirst = first.components(separatedBy: .whitespaces)
            
            if splittedFirst.first?.lowercased() == CreateCommandsMessage.commandPrefix.lowercased().trimmingCharacters(in: .whitespaces) {
                var commands = [Command]()
                
                let remaining = splittedFirst[1...].joined(separator: " ")
                
                if let commandType = CommandTypes(rawValue: remaining) {
                    let firstCommand = Command(commandType: commandType, createCommandsMessageID: messageID)
                    
                    commands.append(firstCommand)
                    
                    return commands
                }
            }
        }
        
        return nil
    }
    
    static func extractFollowersToAdd(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String) -> [Address]? {
        let splitted = plainTextBody.components(separatedBy: .whitespaces)
        
        if
            splitted.count > 1,
            let first = splitted.first,
            first == "Add" || first == "add"
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
            settings.user.address == header.fromAddress.address,
            let to = header.toAddress.first,
            to.address == settings.user.address
        {
            return true
        }
        return false
    }

    static func isCreateCommandMessage(settings: Settings, uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String) -> Bool {
        let len = CreateCommandsMessage.commandPrefix.count
        
        if
            MessageFactory.isFriendlyMailMessage(settings: settings, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
            settings.user.address == header.fromAddress.address,
            let firstLine = plainTextBody.split(whereSeparator: \.isNewline).first,
            firstLine.count > len,
            firstLine[..<firstLine.index(firstLine.startIndex, offsetBy: len)].lowercased() == "\(CreateCommandsMessage.commandPrefix)".lowercased()
        {
            let possibleCommand = firstLine[firstLine.index(firstLine.startIndex, offsetBy: len)..<firstLine.endIndex]
            
            if let _ = CommandTypes(rawValue: String(possibleCommand)) {
                return true
            } else {
                return false
            }
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
