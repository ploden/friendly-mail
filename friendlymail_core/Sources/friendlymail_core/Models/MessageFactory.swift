//
//  MessageFactory.swift
//  friendlymail
//
//  Created by Philip Loden on 8/23/21.
//

import Foundation
import GenericJSON

enum Constants: String {
    case fmShortSubject = "Fm"
    case fmLongSubject = "friendlymail:"
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
    
    public static func createMessage(account: FriendlyMailUser?,
                                     uidWithMailbox: UIDWithMailbox,
                                     header: MessageHeader,
                                     htmlBody: String?,
                                     friendlyMailData: String?,
                                     plainTextBody: String?,
                                     attachments: [Attachment]?,
                                     logger: Logger?) -> (any BaseMessageProtocol)?
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
    
    static func createFriendlyMailMessage(account: FriendlyMailUser?,
                                          uidWithMailbox: UIDWithMailbox,
                                          header: MessageHeader,
                                          htmlBody: String?,
                                          friendlyMailData: String?,
                                          plainTextBody: String?,
                                          attachments: [Attachment]?) -> (any BaseMessageProtocol)?
    {
        if Self.isCreateCommandMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
        {
            return Self.createCreateCommandsMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, friendlyMailData: friendlyMailData, plainTextBody: plainTextBody, attachments: attachments)
        }
        /*
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
            MessageFactory.isCreatePostingMessage(accountAddress: account.email, uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody)
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
            let notifications = MessageFactory.extractNotifications(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, friendlyMailHeader: header.friendlyMailHeader, plainTextBody: plainTextBody)
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
            subject.prefix(Constants.fmLongSubject.rawValue.count).lowercased() == Constants.fmLongSubject.rawValue.lowercased()
            //subject.count >= 14,
            //subject[..<subject.index(subject.startIndex, offsetBy: 14)] == "friendlymail:"
        {
            return true
        } else if
            let subject = subject,
            subject.prefix(Constants.fmShortSubject.rawValue.count).lowercased() == Constants.fmShortSubject.rawValue.lowercased()
            /*
            subject.count >= 2,
            subject[..<subject.index(subject.startIndex, offsetBy: 2)].lowercased() == Constants.fmSubject.rawValue.lowercased() || subject[..<subject.index(subject.startIndex, offsetBy: 2)].lowercased() == Constants.fmSubject.rawValue.lowercased()
             */
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
    
    static func extractInvitees(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String) -> [EmailAddress]? {
        let splitted = plainTextBody.components(separatedBy: .whitespaces)
        
        if
            splitted.count > 1,
            let first = splitted.first,
            first == "Invite" || first == "invite"
        {
            let possibleAddresses = splitted[1..<splitted.count]
            let validAddresses = possibleAddresses.filter { $0.isValidEmail() }
            return validAddresses.compactMap { EmailAddress(displayName: "", address: $0) }
        }
        
        return nil
    }
    
    static func extractCommands(host: EmailAddress, user: EmailAddress, messageID: MessageID, htmlBody: String?, plainTextBody: String?) -> [Command]? {
        guard let plainTextBody = plainTextBody else {
            return nil
        }
        
        if let input = Self.extractCommandInput(plainTextBody: plainTextBody) {
            let commandType: CommandType = {
                if input.lowercased() == "useradd" {
                    return .createAccount
                } else if input.lowercased() == "usermod" {
                    return .setProfilePic
                } else if input.lowercased() == "help" {
                    return .help
                } else if Command.isAddFollowerInput(input: input) {
                    return .follow
                } else {
                    return .unknown
                }
            }()
            
            var counter = 0
            var commands = [Command]()
            
            let firstCommand = Command(index: counter, commandType: commandType, createCommandsMessageID: messageID, input: input, host: host, user: user)
            counter += 1
            commands.append(firstCommand)
            
            return commands
        }
        
        return nil
    }
    
    static func extractCommandInput(plainTextBody: String) -> String? {
        guard plainTextBody.count > 0 else {
            return nil
        }
        
        let splitted = plainTextBody.components(separatedBy: .newlines)
        
        for line in splitted {
            guard line.prefix(CreateCommandsMessage.commandPrefix.count).lowercased() == CreateCommandsMessage.commandPrefix.lowercased() else {
                continue
            }
            
            let components = line.components(separatedBy: .whitespaces)
            
            if components.first?.lowercased() == CreateCommandsMessage.commandPrefix.lowercased().trimmingCharacters(in: .whitespaces) {
                let notEmptyComponents = components.filter { $0.count > 0 }
                let remaining = notEmptyComponents[1...].compactMap { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: " ")
                return remaining
            }
        }
        
        return nil
    }
    
    static func isCreatePostingMessage(accountAddress: EmailAddress, uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String?) -> Bool {
        if
            header.friendlyMailHeader == nil,
            let plainTextBody = plainTextBody,
            plainTextBody.count > 0,
            accountAddress.id == header.fromAddress.id,
            let to = header.toAddress.first,
            to.id == accountAddress.id
        {
            return true
        }
        return false
    }
    
    static func isCreateCommandMessage(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String?) -> Bool {
        guard let plainTextBody = plainTextBody else {
            return false
        }
        
        guard header.friendlyMailHeader?.friendlyMailMessageType == nil else {
            return false // have to do this to avoid false positives with command result messages
        }
        
        let len = CreateCommandsMessage.commandPrefix.count
        
        if
            Self.isFriendlyMailMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
            let firstLine = plainTextBody.split(whereSeparator: \.isNewline).first,
            firstLine.count > len,
            firstLine[..<firstLine.index(firstLine.startIndex, offsetBy: len)].lowercased() == "\(CreateCommandsMessage.commandPrefix)".lowercased()
        {
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
            let commands = MessageFactory.extractCommands(host: header.hostAddress, user: header.fromAddress, messageID: header.messageID, htmlBody: htmlBody, plainTextBody: plainTextBody),
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
            let plainTextBody = plainTextBody,
            plainTextBody.isEmpty == false,
            MessageFactory.isFriendlyMailMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
            let _ = Self.extractCreateCommentAction(subject: header.subject)
        {
            return true
        }
        return false
    }

    static func extractCreateCommentAction(subject: String?) -> CreateCommentAction? {
        if
            let subject = subject,
            subject.contains("Comment"),
            let subjectJSON = Self.json(forFriendlyMailSubject: subject),
            let z = subjectJSON["comment"],
            let x = try? JSONEncoder().encode(z),
            let y = try? JSONDecoder().decode(CreateCommentAction.self, from: x)
        {
            return y
        }
        return nil
    }
    
    static func isCreateLikeMessage(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, plainTextBody: String?) -> Bool {
        if
            let plainTextBody = plainTextBody,
            plainTextBody.isEmpty == false,
            MessageFactory.isFriendlyMailMessage(uidWithMailbox: uidWithMailbox, header: header, htmlBody: htmlBody, plainTextBody: plainTextBody),
            let _ = Self.extractCreateLikeAction(subject: header.subject)
        {
            return true
        }
        return false
    }
    
    static func extractCreateLikeAction(subject: String?) -> CreateLikeAction? {
        if
            let subject = subject,
            subject.contains("Like"),
            let subjectJSON = Self.json(forFriendlyMailSubject: subject),
            let z = subjectJSON["like"],
            let x = try? JSONEncoder().encode(z),
            let y = try? JSONDecoder().decode(CreateLikeAction.self, from: x)
        {
            return y
        }
        return nil
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
    
    static func extractNotifications(uidWithMailbox: UIDWithMailbox, header: MessageHeader, htmlBody: String?, friendlyMailHeader: [HeaderKeyValue]?, plainTextBody: String?) -> [Notification]? {
        if
            let json = Self.json(forFriendlyMailHeader: friendlyMailHeader),
            let notificationsJSON: [JSON] = json["notifications"]?.arrayValue
        {
            let decoder = JSONDecoder()
            
            var notifications = [Notification]()
            
            for notificationJSON in notificationsJSON {
                if
                    let notificationTypeString: String = notificationJSON.notificationType?.stringValue,
                    let notificationType = NotificationType(rawValue: notificationTypeString)
                {
                    switch notificationType {
                    case .newLike:
                        if
                            let x = try? JSONEncoder().encode(notificationJSON),
                            let y = try? decoder.decode(NewLikeNotification.self, from: x)
                        {
                            notifications.append(y)
                        }
                    case .newComment:
                        if
                            let x = try? JSONEncoder().encode(notificationJSON),
                            let y = try? decoder.decode(NewCommentNotification.self, from: x)
                        {
                            notifications.append(y)
                        }
                    case .newPost:
                        if
                            let x = try? JSONEncoder().encode(notificationJSON),
                            let y = try? decoder.decode(NewPostingNotification.self, from: x)
                        {
                            notifications.append(y)
                        }
                    default:
                        break
                    }
                }
            }
            return notifications
        }
        return nil
    }
    
    static func extractCreateCommandSucceededCommandResult(htmlBody: String?, friendlyMailHeader: [HeaderKeyValue]?, friendlyMailData: String?) -> CreateAccountSucceededCommandResult? {
        let results = Self.extractCommandResults(htmlBody: htmlBody, friendlyMailHeader: friendlyMailHeader, friendlyMailData: friendlyMailData)
        return results?.first(where: { $0.commandType == .createAccount} ) as? CreateAccountSucceededCommandResult
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
    
    static func extractCommandResults(htmlBody: String?, friendlyMailHeader: [HeaderKeyValue]?, friendlyMailData: String?) -> [CommandResult]? {
        let decoder = JSONDecoder()
        
        if
            let json = friendlyMailData,
            let dict = try? decoder.decode([String:[CommandResult]].self, from: json.data(using: .utf8)!),
            let commandResults = dict["commandResults"]
        {
            return commandResults
        }
        
        if
            let json = Self.json(forFriendlyMailHeader: friendlyMailHeader),
            let commandResultsJSON: [JSON] = json["commandResults"]?.arrayValue
        {
            let commandResults: [CommandResult] = commandResultsJSON.compactMap { commandResultJSON in
                if
                    let commandTypeString = commandResultJSON.command?.commandType?.stringValue,
                    let commandType = CommandType(rawValue: commandTypeString)
                {
                    switch commandType {
                    case .createAccount:
                        let exitCodeInt = Int(commandResultJSON.exitCode!.doubleValue!)
                        
                        if let x = try? JSONEncoder().encode(commandResultJSON) {
                            if CommandExitCode(rawValue: exitCodeInt)! == CommandExitCode.success {
                                if let y = try? decoder.decode(CreateAccountSucceededCommandResult.self, from: x) {
                                    return y
                                }
                            } else {
                                if let y = try? decoder.decode(CommandResult.self, from: x) {
                                    return y
                                }
                            }
                        }
                    case .setProfilePic:
                        if let x = try? JSONEncoder().encode(commandResultJSON) {
                            if let y = try? decoder.decode(SetProfilePicSucceededCommandResult.self, from: x) {
                                return y
                            }
                        }
                    case .follow:
                        if let x = try? JSONEncoder().encode(commandResultJSON) {
                            if let y = try? decoder.decode(AddFollowersSucceededCommandResult.self, from: x) {
                                return y
                            }
                        }
                    default:
                        if let x = try? JSONEncoder().encode(commandResultJSON) {
                            if let y = try? decoder.decode(CommandResult.self, from: x) {
                                return y
                            }
                        }
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
    
    static func json(forFriendlyMailSubject subject: String?) -> JSON? {
        if let subject = subject {
            let splitted = subject.components(separatedBy: .whitespaces)
            
            if
                splitted.count > 2
            {
                let third = splitted[2]
                let json = JSON.decode(fromBase64JSON: third)
                return json
            }
        }
        return nil
    }
}
