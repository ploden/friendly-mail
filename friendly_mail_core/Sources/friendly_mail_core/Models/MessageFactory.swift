//
//  MessageFactory.swift
//  friendly-mail
//
//  Created by Philip Loden on 8/23/21.
//

import Foundation

enum FriendlyMailMessageType: String {
    case invite = "invite"
    case notifications = "notifications"
    case commandResult = "command_result"
    case createAccountSucceededCommandResult = "create_account_succeeded_command_result"
}

public struct MessageFactory {
    
    static func logMessage(logger: Logger?, typeName: String, header: MessageHeader, plainTextBody: String?) {
        if let logger = logger {
            let shortBody = String(plainTextBody?.prefix(30) ?? "")
            let from = header.fromAddress.address
            let to = header.toAddress.first?.address ?? ""
            logger.log(message: "MessageFactory: CREATING \(typeName). from: \(from) to: \(to) subject: \(header.subject ?? "") body: \(shortBody)")
        }
    }
    
    public static func createMessage(account: FriendlyMailAccount?,
                                     uidWithMailbox: UIDWithMailbox,
                                     header: MessageHeader,
                                     htmlBody: String?,
                                     friendlyMailData: String?,
                                     plainTextBody: String?,
                                     attachments: [Attachment]?,
                                     logger: Logger?) -> BaseMessage?
    {
        if MessageFactory.isFriendlyMailMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody) {
            if
                MessageFactory.isCreateCommandMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
                let commands = MessageFactory.extractCommands(messageID: header.messageID, htmlBody: htmlBody, plainTextBody: plainTextBody),
                commands.count > 0
            {
                MessageFactory.logMessage(logger: logger, typeName: "CreateCommandsMessage", header: header, plainTextBody: plainTextBody)
                return CreateCommandsMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments, commands: commands)
            }
            else if
                MessageFactory.isCreateAccountSucceededCommandResultMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
                let createCommandsMessageID = header.friendlyMailHeader?.first(where: { $0.key == HeaderKey.createCommandsMessageID.rawValue })?.value,
                let result = MessageFactory.extractCreateCommandSucceededCommandResult(htmlBody: htmlBody, friendlyMailHeader: header.friendlyMailHeader, friendlyMailData: friendlyMailData)
            {
                MessageFactory.logMessage(logger: logger, typeName: "CreateAccountSucceededCommandResultMessage", header: header, plainTextBody: plainTextBody)
                return CreateAccountSucceededCommandResultMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments, account: result.account, commandResult: result)
            }
            else if
                MessageFactory.isCommandResultMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
                let createCommandsMessageID = header.friendlyMailHeader?.first(where: { $0.key == HeaderKey.createCommandsMessageID.rawValue })?.value,
                let commandResult = MessageFactory.extractCommandResult(htmlBody: htmlBody, friendlyMailHeader: header.friendlyMailHeader, friendlyMailData: friendlyMailData)
            {
                MessageFactory.logMessage(logger: logger, typeName: "CommandResultMessage", header: header, plainTextBody: plainTextBody)
                return CommandResultMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments, commandResult: commandResult)
            }
            /*
             else if
             MessageFactory.isCreateInviteMessage(accountAddress: accountAddress, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
             let invitees = MessageFactory.extractInvitees(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
             invitees.count > 0
             {
             return CreateInvitesMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments, invitees: invitees, inviter: header.fromAddress)
             }
             else if
             MessageFactory.isCreateAddFollowersMessage(accountAddress: accountAddress, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
             let followersToAdd = MessageFactory.extractFollowersToAdd(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
             let followee = header.toAddress.first
             {
             return CreateAddFollowersMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments, followers: followersToAdd, followee: followee, frequency: .realtime)
             }
             */
            else if
                MessageFactory.isInviteMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
                let createInvitesMessageID = header.friendlyMailHeader?.first(where: { $0.key == HeaderKey.createInvitesMessageID.rawValue })?.value
            {
                MessageFactory.logMessage(logger: logger, typeName: "InviteMessage", header: header, plainTextBody: plainTextBody)
                let invite = Invite(inviter: header.fromAddress, invitee: header.toAddress.first!, createInvitesMessageID: createInvitesMessageID)
                return InviteMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments, invite: invite)
            }
            else if
                let account = account,
                MessageFactory.isCreatePostMessage(accountAddress: account.user, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
            {
                MessageFactory.logMessage(logger: logger, typeName: "CreatePostingMessage", header: header, plainTextBody: plainTextBody)
                return CreatePostingMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments)
            }
            /*
             else if
             MessageFactory.isCreateSubscriptionMessage(accountAddress: accountAddress, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
             let frequency = MessageFactory.extractSubscriptionFrequency(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
             let followee = header.toAddress.first
             {
             return CreateSubscriptionMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments, follower: header.fromAddress, followee: followee, frequency: frequency)
             }
             */
            else if
                MessageFactory.isNotificationsMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
                let notifications = MessageFactory.extractNotifications(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
            {
                MessageFactory.logMessage(logger: logger, typeName: "NotificationsMessage", header: header, plainTextBody: plainTextBody)
                return NotificationsMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments, notifications: notifications)
            }
            else if
                MessageFactory.isCreateCommentMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
            {
                MessageFactory.logMessage(logger: logger, typeName: "CreateCommentMessage", header: header, plainTextBody: plainTextBody)
                return CreateCommentMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments)
            }
            else if
                MessageFactory.isCreateLikeMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
            {
                MessageFactory.logMessage(logger: logger, typeName: "CreateLikeMessage", header: header, plainTextBody: plainTextBody)
                return CreateLikeMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments)
            }
        }
        MessageFactory.logMessage(logger: logger, typeName: "Message", header: header, plainTextBody: plainTextBody ?? "")
        return Message(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments)
    }

    static func isInviteMessage(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String?) -> Bool {
        if
            let messageType = header.friendlyMailHeader?.first(where: { $0.key == HeaderKey.type.rawValue })?.value,
            messageType == FriendlyMailMessageType.invite.rawValue
        {
            return true
        }
        return false
    }

    static func isFriendlyMailMessage(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String?) -> Bool {
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
    
    /*
    static func isCreateAddFollowersMessage(account: Account, uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String) -> Bool {
        if header.fromAddress.address == account.user.address {
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
     */
    
    /*
    static func isCreateInviteMessage(account: Account, uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String) -> Bool {
        if header.fromAddress.address == account.user.address {
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
     */

    /*
    static func isCreateSubscriptionMessage(account: Account, uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String) -> Bool {
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
     */

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

    static func extractCommands(messageID: MessageID, htmlBody: String?, plainTextBody: String?) -> [Command]? {
        guard let plainTextBody = plainTextBody else {
            return nil
        }
        
        let splitted = plainTextBody.components(separatedBy: .newlines)
        
        var counter = 0
        
        if let first = splitted.first {
            let splittedFirst = first.components(separatedBy: .whitespaces)
            
            if splittedFirst.first?.lowercased() == CreateCommandsMessage.commandPrefix.lowercased().trimmingCharacters(in: .whitespaces) {
                var commands = [Command]()
                
                let remaining = splittedFirst[1...].joined(separator: " ")
                
                if remaining.lowercased() == "create account" {
                    let firstCommand = CreateAccountCommand(index: counter, commandType: .createAccount, createCommandsMessageID: messageID, input: remaining)
                    counter += 1
                    
                    commands.append(firstCommand)
                } else {
                    let firstCommand = UnknownCommand(index: counter, commandType: .unknown, createCommandsMessageID: messageID, input: remaining)
                    counter += 1
                    
                    commands.append(firstCommand)
                }
                
                return commands
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
    
    static func isCreatePostMessage(accountAddress: Address, uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String?) -> Bool {
        if
            header.friendlyMailHeader == nil,
            accountAddress.address == header.fromAddress.address,
            let to = header.toAddress.first,
            to.address == accountAddress.address
        {
            return true
        }
        return false
    }

    static func isCreateCommandMessage(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String?) -> Bool {
        guard let plainTextBody = plainTextBody else {
            return false
        }
        
        let len = CreateCommandsMessage.commandPrefix.count
        
        if
            MessageFactory.isFriendlyMailMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
            let firstLine = plainTextBody.split(whereSeparator: \.isNewline).first,
            firstLine.count > len,
            firstLine[..<firstLine.index(firstLine.startIndex, offsetBy: len)].lowercased() == "\(CreateCommandsMessage.commandPrefix)".lowercased()
        {
            /*
            let possibleCommand = firstLine[firstLine.index(firstLine.startIndex, offsetBy: len)..<firstLine.endIndex]
            
            if let _ = CommandTypes(rawValue: String(possibleCommand)) {
                return true
            } else {
                return false
            }
             */
            return true
        }
        return false
    }
    
    static func isCommandResultMessage(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String?) -> Bool {
        if
            let messageType = header.friendlyMailHeader?.first(where: { $0.key == HeaderKey.type.rawValue })?.value,
            messageType == FriendlyMailMessageType.commandResult.rawValue
        {
            return true
        }
        return false
    }

    static func isCreateAccountSucceededCommandResultMessage(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String?) -> Bool {
        if
            let messageType = header.friendlyMailHeader?.first(where: { $0.key == HeaderKey.type.rawValue })?.value,
            messageType == FriendlyMailMessageType.createAccountSucceededCommandResult.rawValue
        {
            return true
        }
        return false
    }
    
    static func isCreateCommentMessage(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String?) -> Bool {
        if
            MessageFactory.isFriendlyMailMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
            let subject = header.subject,
            subject.contains("Comment:")
        {
            return true
        }
        return false
    }
    
    static func isCreateLikeMessage(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String?) -> Bool {
        if
            MessageFactory.isFriendlyMailMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
            let subject = header.subject,
            subject.contains("Like:")
        {
            return true
        }
        return false
    }
    
    static func isNotificationsMessage(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String?) -> Bool {
        if
            let messageType = header.friendlyMailHeader?.first(where: { $0.key == HeaderKey.type.rawValue })?.value,
            messageType == FriendlyMailMessageType.notifications.rawValue
        {
            return true
        }
        return false
    }
    
    static func extractNotifications(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String?) -> [Notification]? {
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
                case .createCommandsMessageID:
                    return nil
                case .base64JSON:
                    return nil
                }
            }
            return nil
        }
        return notifications
    }

    static func extractCreateCommandSucceededCommandResult(htmlBody: String?, friendlyMailHeader: [HeaderKeyValue]?, friendlyMailData: String?) -> CreateAccountSucceededCommandResult? {
        let decoder = JSONDecoder()
                
        if
            let json = friendlyMailData,
            let dict = try? decoder.decode([String:CreateAccountSucceededCommandResult].self, from: json.data(using: .utf8)!),
            let commandResult = dict["commandResult"]
        {
            return commandResult
        } else if
            let base64JSON = friendlyMailHeader?.first(where: { $0.key == HeaderKey.base64JSON.rawValue })?.value,
            let decodedData = Data(base64Encoded: base64JSON.paddedForBase64Decoding, options: .ignoreUnknownCharacters),
            let decodedDataString = String(data: decodedData, encoding: .utf8),
            let jsonData = decodedDataString.data(using: .utf8),
            let dict = try? decoder.decode([String:CreateAccountSucceededCommandResult].self, from: jsonData),
            let commandResult = dict["commandResult"]
        {
            return commandResult
        }

        return nil
    }
    
    static func extractCommandResult(htmlBody: String?, friendlyMailHeader: [HeaderKeyValue]?, friendlyMailData: String?) -> CommandResult? {
        //let x = header.friendlyMailHeader?.first(where: { $0.key == HeaderKey.createCommandsMessageID.rawValue })?.value
        
        let decoder = JSONDecoder()
                
        if
            /*
            let htmlBody = htmlBody,
            let doc: Document = try? SwiftSoup.parse(htmlBody),
            let script = try? doc.head()?.select("script").first { $0.id() == "friendly-mail-data" },
        let json = try? script.html(),
             */
            let json = friendlyMailData,
            let dict = try? decoder.decode([String:CommandResult].self, from: json.data(using: .utf8)!),
            let commandResult = dict["commandResult"]
        {
            return commandResult
        } else if
            let friendlyMailHeader = friendlyMailHeader,
            let json = friendlyMailHeader.first(where: { $0.key == HeaderKey.base64JSON.rawValue })?.value,
            let dict = try? decoder.decode([String:CommandResult].self, from: json.data(using: .utf8)!),
            let commandResult = dict["commandResult"]
        {
            return commandResult
        }

        /*
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
                case .createCommandsMessageID:
                    return nil
                }
            }
            return nil
        }
        return notifications
         */
        return nil
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
 
    static func createAccountMessage(uidWithMailbox: UIDWithMailbox,
                                     header: MessageHeader,
                                     htmlBody: String?,
                                     friendlyMailData: String?,
                                     plainTextBody: String?,
                                     attachments: [Attachment]?) -> CommandResultMessage?
    {
        if MessageFactory.isFriendlyMailMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody) {
            if
                MessageFactory.isCommandResultMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
                let createCommandsMessageID = header.friendlyMailHeader?.first(where: { $0.key == HeaderKey.createCommandsMessageID.rawValue })?.value,
                let commandResult = MessageFactory.extractCommandResult(htmlBody: htmlBody, friendlyMailHeader: header.friendlyMailHeader, friendlyMailData: friendlyMailData)
            {
                return CommandResultMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments, commandResult: commandResult)
            }
        }
        return nil
    }
    
}
