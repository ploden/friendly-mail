//
//  CommandResultMessageDraft.swift
//  
//
//  Created by Philip Loden on 2/13/23.
//

import Foundation
import GenericJSON

struct CommandResultMessageDraft: AnyMessageDraft {
    var commandResults: [CommandResult]
    
    var to: [Address]
    
    var subject: String
    
    var htmlBody: String?
    
    var plainTextBody: String
    
    var friendlyMailHeaders: [HeaderKeyValue]?
    
    init?(to: [Address], commandResults: [CommandResult], theme: Theme) {
        self.to = to
        self.commandResults = commandResults
        
        let context: [String : Any] = [
            "firstCommandResult": commandResults.first!,
            "commandInput": commandResults.first!.command.input,
            "commandResults": commandResults,
            "signature": "\n\(Template.PlainText.signature.rawValue)",
            "likeBody": Template.PlainText.like.rawValue
        ]
        
        if let rendered = try? theme.render(type: CommandResultMessageDraft.self, context: context) {
            self.subject = rendered.subject
            self.plainTextBody = rendered.plainTextBody
            self.htmlBody = rendered.htmlBody
            
            var friendlyMailHeaders = [
                HeaderKeyValue(key: HeaderKey.createCommandsMessageID.rawValue, commandResults.first!.createCommandMessageID),
            ]
            
            friendlyMailHeaders.append(HeaderKeyValue(key: HeaderKey.type.rawValue, value: FriendlyMailMessageType.commandResult.rawValue))

            /*
            if commandResult is CreateAccountSucceededCommandResult {
                friendlyMailHeaders.append(HeaderKeyValue(key: HeaderKey.type.rawValue, value: FriendlyMailMessageType.createAccountSucceededCommandResult.rawValue))
            } else if commandResult is SetProfilePicSucceededCommandResult {
                friendlyMailHeaders.append(HeaderKeyValue(key: HeaderKey.type.rawValue, value: FriendlyMailMessageType.setProfilePicSucceededCommandResult.rawValue))
            } else if commandResult is AddFollowersSucceededCommandResult {
                friendlyMailHeaders.append(HeaderKeyValue(key: HeaderKey.type.rawValue, value: FriendlyMailMessageType.addFollowersSucceededCommandResult.rawValue))
            } else {
                friendlyMailHeaders.append(HeaderKeyValue(key: HeaderKey.type.rawValue, value: FriendlyMailMessageType.commandResult.rawValue))
            }
            */
               
            /*
            let commandResultsJSON: [JSON] = commandResults.compactMap { commandResult in
                if let commandResult = commandResult as? CommandResult {
                    return try! JSON(encodable: commandResult)
                }
                return nil
            }
             */
                        
            let json: JSON = [
                //"commandResults": JSON.array(commandResultsJSON)
                "commandResults": try! JSON(encodable: commandResults)
            ]

            let base64JSONString = json.encodeAsBase64JSON()
            friendlyMailHeaders.append(HeaderKeyValue(key: HeaderKey.base64JSON.rawValue, base64JSONString))
            
            self.friendlyMailHeaders = friendlyMailHeaders
        } else {
            return nil
        }
    }
}
