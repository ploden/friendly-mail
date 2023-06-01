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
    
    var to: [EmailAddress]
    
    var subject: String
    
    var htmlBody: String?
    
    var plainTextBody: String
    
    var friendlyMailHeaders: [HeaderKeyValue]?
    
    init?(to: [EmailAddress], commandResults: [CommandResult], theme: Theme) {
        guard let firstCommandResult = commandResults.first else {
            return nil
        }
        
        self.to = to
        self.commandResults = commandResults
        
        let firstCommandResultContext = CommandResultContext(
            commandInput: firstCommandResult.command.input,
            message: firstCommandResult.message
        )
        
        let commandResultMessageContext = CommandResultMessageContext(
            firstCommandResultContext: firstCommandResultContext,
            signature: "\(Template.PlainText.signature.rawValue)"
        )
        
        let contextAny = try? commandResultMessageContext.encode()
        let contextDict = contextAny as! [String : Any]
        
        if let rendered = try? theme.render(type: CommandResultMessageDraft.self, context: contextDict) {
            self.subject = rendered.subject
            self.plainTextBody = rendered.plainTextBody
            self.htmlBody = rendered.htmlBody
            
            var friendlyMailHeaders = [
                HeaderKeyValue(key: HeaderKey.createCommandsMessageID.rawValue, commandResults.first!.createCommandMessageID),
            ]
            
            friendlyMailHeaders.append(HeaderKeyValue(key: HeaderKey.type.rawValue, value: FriendlyMailMessageType.commandResult.rawValue))
      
            let json: JSON = [
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
