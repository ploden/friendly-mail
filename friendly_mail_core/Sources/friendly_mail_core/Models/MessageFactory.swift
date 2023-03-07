//
//  MessageFactory.swift
//  friendly-mail
//
//  Created by Philip Loden on 8/23/21.
//

import Foundation
import GenericJSON

enum Constants: String {
    case fmSubject = "Fm"
}

enum FriendlyMailMessageType: String {
    case invite = "invite"
    case notifications = "notifications"
    case commandResult = "command_result"
    //case createAccountSucceededCommandResult = "create_account_succeeded_command_result"
    case setProfilePicSucceededCommandResult = "set_profile_pic_succeeded_command_result"
    case addFollowersSucceededCommandResult = "add_followers_succeeded_command_result"
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
                                     logger: Logger?) -> AnyBaseMessage?
    {
        let friendlyMailMessage = {
            if MessageFactory.isFriendlyMailMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody) {
                return MessageFactory.createFriendlyMailMessage(account: account, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, friendlyMailData: friendlyMailData, plainTextBody: plainTextBody, attachments: attachments)
            }
            return nil
        }()
        
        let message = friendlyMailMessage ?? Message(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments)
        let messageType = String(describing: message)
        MessageFactory.logMessage(logger: logger, typeName: messageType, header: header, plainTextBody: plainTextBody ?? "")
        return message
    }
    
    static func createFriendlyMailMessage(account: FriendlyMailAccount?,
                                          uidWithMailbox: UIDWithMailbox,
                                          header: MessageHeader,
                                          htmlBody: String?,
                                          friendlyMailData: String?,
                                          plainTextBody: String?,
                                          attachments: [Attachment]?) -> AnyBaseMessage?
    {
        if Self.isCreateCommandMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
        {
            return Self.createCreateCommandsMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, friendlyMailData: friendlyMailData, plainTextBody: plainTextBody, attachments: attachments)
        }
        /*
        else if Self.isSetProfilePicSucceededCommandResultMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
        {
            return Self.createSetProfilePicSucceededCommandResultMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, friendlyMailData: friendlyMailData, plainTextBody: plainTextBody, attachments: attachments)
        }
        else if Self.isAddFollowersSucceededCommandResultMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
        {
            return Self.createAddFollowersSucceededCommandResultMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, friendlyMailData: friendlyMailData, plainTextBody: plainTextBody, attachments: attachments)
        }
         */
        else if Self.isCommandResultMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
        {
            return Self.createCommandResultsMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, friendlyMailData: friendlyMailData, plainTextBody: plainTextBody, attachments: attachments)
        }
        /*
         else if
         MessageFactory.isCreateInviteMessage(accountAddress: accountAddress, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
         let invitees = MessageFactory.extractInvitees(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
         invitees.count > 0
         {
         return CreateInvitesMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments, invitees: invitees, inviter: header.fromAddress)
         }
         */
        else if
            MessageFactory.isInviteMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
            let createInvitesMessageID = header.friendlyMailHeader?.first(where: { $0.key == HeaderKey.createInvitesMessageID.rawValue })?.value
        {
            let invite = Invite(inviter: header.fromAddress, invitee: header.toAddress.first!, createInvitesMessageID: createInvitesMessageID)
            return InviteMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments, invite: invite)
        }
        else if
            let account = account,
            MessageFactory.isCreatePostMessage(accountAddress: account.user, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
        {
            return CreatePostingMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments)
        }
        /*
         else if
         MessageFactory.isCreateFollowMessage(accountAddress: accountAddress, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
         let frequency = MessageFactory.extractFollowFrequency(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
         let followee = header.toAddress.first
         {
         return CreateFollowMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments, follower: header.fromAddress, followee: followee, frequency: frequency)
         }
         */
        else if
            MessageFactory.isNotificationsMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
            let notifications = MessageFactory.extractNotifications(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
        {
            return NotificationsMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments, notifications: notifications)
        }
        else if
            MessageFactory.isCreateCommentMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
        {
            return CreateCommentMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments)
        }
        else if
            MessageFactory.isCreateLikeMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
        {
            return CreateLikeMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments)
        }
        return nil
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
            subject[..<subject.index(subject.startIndex, offsetBy: 2)].lowercased() == Constants.fmSubject.rawValue.lowercased() || subject[..<subject.index(subject.startIndex, offsetBy: 2)].lowercased() == Constants.fmSubject.rawValue.lowercased()
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
     static func isCreateFollowMessage(account: Account, uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String) -> Bool {
     let splitted = plainTextBody.components(separatedBy: .whitespaces)
     
     if
     splitted.count > 1,
     let first = splitted.first,
     first == "Follow" || first == "follow"
     {
     let frequency = MessageFactory.extractFollowFrequency(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
     return frequency != nil
     }
     
     return false
     }
     */
    
    static func extractUpdateFrequency(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String) -> UpdateFrequency? {
        let splitted = plainTextBody.components(separatedBy: .whitespaces)
        
        if
            splitted.count > 1,
            let first = splitted.first,
            first == "Follow" || first == "follow"
        {
            let possibleFrequency = splitted[1]
            return UpdateFrequency(rawValue: possibleFrequency.lowercased())
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
                    let firstCommand = Command(index: counter, commandType: .createAccount, createCommandsMessageID: messageID, input: remaining)
                    counter += 1
                    commands.append(firstCommand)
                } else if remaining.lowercased() == "set profile pic" {
                    let firstCommand = Command(index: counter, commandType: .setProfilePic, createCommandsMessageID: messageID, input: remaining)
                    counter += 1
                    commands.append(firstCommand)
                } else if Command.isAddFollowerInput(input: remaining) {
                    let firstCommand = Command(index: counter, commandType: .addFollowers, createCommandsMessageID: messageID, input: remaining)
                    counter += 1
                    commands.append(firstCommand)
                } else {
                    let firstCommand = Command(index: counter, commandType: .unknown, createCommandsMessageID: messageID, input: remaining)
                    counter += 1
                    commands.append(firstCommand)
                }
                
                return commands
            }
        }
        
        return nil
    }
    
    static func extractFollowersToAdd(plainTextBody: String) -> [Address] {
        let splitted = plainTextBody.components(separatedBy: .whitespaces)
        
        if
            Command.isAddFollowerInput(input: plainTextBody),
            splitted.count > 2
        {
            let possibleAddresses = splitted[2..<splitted.count]
            let validAddresses = possibleAddresses.filter { $0.isValidEmail() }
            return validAddresses.compactMap { Address(name: "", address: $0) }
        }

        return []
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
            Self.isFriendlyMailMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
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
    
    static func createCreateCommandsMessage(uidWithMailbox: UIDWithMailbox,
                                           header: MessageHeader,
                                           htmlBody: String?,
                                           friendlyMailData: String?,
                                           plainTextBody: String?,
                                           attachments: [Attachment]?) -> CreateCommandsMessage?
    {
        if
            let commands = MessageFactory.extractCommands(messageID: header.messageID, htmlBody: htmlBody, plainTextBody: plainTextBody),
            commands.count > 0
        {
            return CreateCommandsMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments, commands: commands)
        }
        return nil
    }
    
    static func isCommandResultMessage(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String?) -> Bool {
        let isCommandResult = header.friendlyMailHeader?.friendlyMailMessageType == .commandResult
        return isCommandResult
    }
    
    static func createCommandResultsMessage(uidWithMailbox: UIDWithMailbox,
                                           header: MessageHeader,
                                           htmlBody: String?,
                                           friendlyMailData: String?,
                                           plainTextBody: String?,
                                           attachments: [Attachment]?) -> CommandResultsMessage?
    {
        if let results = Self.extractCommandResults(htmlBody: htmlBody, friendlyMailHeader: header.friendlyMailHeader, friendlyMailData: friendlyMailData)
        {
            let message = CommandResultsMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments, commandResults: results)
            return message
        }
        return nil
    }
    
    static func isCreateAccountSucceededCommandResultMessage(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String?) -> Bool {
        return false
        //return header.friendlyMailHeader?.friendlyMailMessageType == .createAccountSucceededCommandResult
    }

    static func isSetProfilePicSucceededCommandResultMessage(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String?) -> Bool {
        return header.friendlyMailHeader?.friendlyMailMessageType == .setProfilePicSucceededCommandResult
    }
    
    /*
    static func createSetProfilePicSucceededCommandResultMessage(uidWithMailbox: UIDWithMailbox,
                                                                 header: MessageHeader,
                                                                 htmlBody: String?,
                                                                 friendlyMailData: String?,
                                                                 plainTextBody: String?,
                                                                 attachments: [Attachment]?) -> SetProfilePicSucceededCommandResultMessage?
    {
        if let result = MessageFactory.extractSetProfilePicSucceededCommandResult(htmlBody: htmlBody, friendlyMailHeader: header.friendlyMailHeader, friendlyMailData: friendlyMailData)
        {
            let message = SetProfilePicSucceededCommandResultMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments, setProfilePicSucceededCommandResult: result)
            return message
        }
        return nil
    }
    
    static func isAddFollowersSucceededCommandResultMessage(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String?) -> Bool {
        return header.friendlyMailHeader?.friendlyMailMessageType == .addFollowersSucceededCommandResult
    }
    
    static func createAddFollowersSucceededCommandResultMessage(uidWithMailbox: UIDWithMailbox,
                                                                 header: MessageHeader,
                                                                 htmlBody: String?,
                                                                 friendlyMailData: String?,
                                                                 plainTextBody: String?,
                                                                 attachments: [Attachment]?) -> AddFollowersSucceededCommandResultMessage?
    {
        if let result = Self.extractAddFollowersSucceededCommandResult(htmlBody: htmlBody, friendlyMailHeader: header.friendlyMailHeader, friendlyMailData: friendlyMailData)
        {
            let message = AddFollowersSucceededCommandResultMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments, addFollowersSucceededCommandResult: result)
            return message
        }
        return nil
    }
     */
    
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
        
        let results = Self.extractCommandResults(htmlBody: htmlBody, friendlyMailHeader: friendlyMailHeader, friendlyMailData: friendlyMailData)
        return results?.first(where: { $0.commandType == .createAccount} ) as? CreateAccountSucceededCommandResult
        
        let decoder = JSONDecoder()
        
        if
            let json = friendlyMailData,
            let dict = try? decoder.decode([String:CreateAccountSucceededCommandResult].self, from: json.data(using: .utf8)!),
            let commandResult = dict["commandResult"]
        {
            return commandResult
        } else if
            let json = MessageFactory.base64JSONString(forFriendlyMailHeader: friendlyMailHeader),
            let createAccountSucceededCommandResult = CreateAccountSucceededCommandResult.decode(fromBase64JSON: json)
        {
            return createAccountSucceededCommandResult
        }
        
        return nil
    }
    
    static func extractSetProfilePicSucceededCommandResult(htmlBody: String?, friendlyMailHeader: [HeaderKeyValue]?, friendlyMailData: String?) -> SetProfilePicSucceededCommandResult? {
        let decoder = JSONDecoder()
        
        if
            let json = friendlyMailData,
            let dict = try? decoder.decode([String:SetProfilePicSucceededCommandResult].self, from: json.data(using: .utf8)!),
            let commandResult = dict["commandResult"]
        {
            return commandResult
        } else if
            let json = MessageFactory.base64JSONString(forFriendlyMailHeader: friendlyMailHeader),
            let setProfilePicSucceededCommandResult = SetProfilePicSucceededCommandResult.decode(fromBase64JSON: json)
        {
            return setProfilePicSucceededCommandResult
        }
        
        return nil
    }
    
    static func extractAddFollowersSucceededCommandResult(htmlBody: String?, friendlyMailHeader: [HeaderKeyValue]?, friendlyMailData: String?) -> AddFollowersSucceededCommandResult? {
        let decoder = JSONDecoder()
        
        if
            let json = friendlyMailData,
            let dict = try? decoder.decode([String:AddFollowersSucceededCommandResult].self, from: json.data(using: .utf8)!),
            let commandResult = dict["commandResult"]
        {
            return commandResult
        } else if
            let json = MessageFactory.base64JSONString(forFriendlyMailHeader: friendlyMailHeader),
            let addFollowersSucceededCommandResult = AddFollowersSucceededCommandResult.decode(fromBase64JSON: json)
        {
            return addFollowersSucceededCommandResult
        }
        
        return nil
    }
    
    static func extractCommandResults(htmlBody: String?, friendlyMailHeader: [HeaderKeyValue]?, friendlyMailData: String?) -> [any AnyCommandResult]? {
        let decoder = JSONDecoder()
        
        if
            let json = friendlyMailData,
            let dict = try? decoder.decode([String:[CommandResult]].self, from: json.data(using: .utf8)!),
            let commandResults = dict["commandResults"]
        {
            return commandResults
        } else if
            let json = Self.json(forFriendlyMailHeader: friendlyMailHeader),
            let commandResultsJSON: [JSON] = json["commandResults"]?.arrayValue
        {
            let commandResults = commandResultsJSON.compactMap { commandResultJSON in
                if
                    let commandTypeString = commandResultJSON.command?.commandType?.stringValue,
                    let commandType = CommandType(rawValue: commandTypeString)
                {
                    switch commandType {
                    case .createAccount:
                        if let x = try? JSONEncoder().encode(commandResultJSON) {
                            let y = try? decoder.decode(CreateAccountSucceededCommandResult.self, from: x)
                            return y
                        }
                    default:
                        return nil
                    }
                }
                return nil
            }
            return commandResults
        }

        return nil
    }
    
    static func json(forFriendlyMailHeader friendlyMailHeader: [HeaderKeyValue]?) -> JSON? {
        if
            let base64JSONString = Self.base64JSONString(forFriendlyMailHeader: friendlyMailHeader),
            let json = JSON.decode(fromBase64JSON: base64JSONString)
        {
            return json
        }
        return nil
    }
    
    static func base64JSONString(forFriendlyMailHeader friendlyMailHeader: [HeaderKeyValue]?) -> String? {
        return friendlyMailHeader?.first(where: { $0.key == HeaderKey.base64JSON.rawValue })?.value
/*
        if
            let base64JSON = friendlyMailHeader?.first(where: { $0.key == HeaderKey.base64JSON.rawValue })?.value,
            let decodedData = Data(base64Encoded: base64JSON.paddedForBase64Decoding, options: .ignoreUnknownCharacters),
            let decodedDataString = String(data: decodedData, encoding: .utf8)
        {
            return decodedDataString
        }
        return nil
 */
    }
    
    static func base64JSONData(forFriendlyMailHeader friendlyMailHeader: [HeaderKeyValue]?) -> Data? {
        if
            let decodedDataString = MessageFactory.base64JSONString(forFriendlyMailHeader: friendlyMailHeader),
            let jsonData = decodedDataString.data(using: .utf8)
        {
            return jsonData
        }
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
                                     attachments: [Attachment]?) -> CommandResultsMessage?
    {
        if MessageFactory.isFriendlyMailMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody) {
            if
                MessageFactory.isCommandResultMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
                let createCommandsMessageID = header.friendlyMailHeader?.first(where: { $0.key == HeaderKey.createCommandsMessageID.rawValue })?.value,
                let commandResults = MessageFactory.extractCommandResults(htmlBody: htmlBody, friendlyMailHeader: header.friendlyMailHeader, friendlyMailData: friendlyMailData)
            {
                return CommandResultsMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody, attachments: attachments, commandResults: commandResults)
            }
        }
        return nil
    }
    
}
