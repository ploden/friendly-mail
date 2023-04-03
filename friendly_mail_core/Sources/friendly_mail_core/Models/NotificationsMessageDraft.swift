//
//  NewLikeNotificationDraft.swift
//  
//
//  Created by Philip Loden on 3/21/23.
//

import Foundation
import GenericJSON

struct NotificationsMessageDraft: AnyMessageDraft {
    var notifications: [Notification]
    
    var to: [Address]
    
    var subject: String
    
    var htmlBody: String?
    
    var plainTextBody: String
    
    var friendlyMailHeaders: [HeaderKeyValue]?
    
    init?(to: [Address], notifications: [Notification], theme: Theme, messages: MessageStore) {
        self.to = to
        self.notifications = notifications
    
        let combined: [[String : Any]] = notifications.compactMap {
                switch $0.notificationType {
                case .newLike:
                    if
                        let newLikeNotification = $0 as? NewLikeNotification,
                        let createLikeMessage = messages.getMessage(for: newLikeNotification.createLikeMessageID) as? CreateLikeMessage,
                        let createPostMessage = messages.getMessage(for: createLikeMessage.like.parentItemMessageID) as? CreatePostingMessage
                    {
                        return [
                            "notification": newLikeNotification,
                            "type": newLikeNotification.notificationType.rawValue,
                            "createLikeMessage": createLikeMessage,
                            "createPostMessage": createPostMessage
                            ]
                    }
                case .newComment:
                    if
                        let newCommentNotification = $0 as? NewCommentNotification,
                        let createCommentMessage = messages.getMessage(for: newCommentNotification.createCommentMessageID) as? CreateCommentMessage,
                        let createPostMessage = messages.getMessage(for: createCommentMessage.comment.parentItemMessageID) as? CreatePostingMessage
                    {
                        return [
                            "notification": newCommentNotification,
                            "type": newCommentNotification.notificationType.rawValue,
                            "createCommentMessage": createCommentMessage,
                            "createPostMessage": createPostMessage
                            ]
                    }
                case .newPost:
                    if
                        let newPostNotification = $0 as? NewPostingNotification,
                        let createPostMessage = messages.getMessage(for: newPostNotification.createPostingMessageID) as? CreatePostingMessage
                    {
                        return [
                            "notification": newPostNotification,
                            "type": newPostNotification.notificationType.rawValue,
                            "createPostMessage": createPostMessage
                        ]
                    }
                default:
                    return nil
                }
            return nil
        }
        
        let context: [String : Any] = [
            "notifications": combined,
            "signature": "\n\(Template.PlainText.signature.rawValue)",
            "likeBody": Template.PlainText.like.rawValue,
            "firstNotification": combined.first!
        ]   

        if let rendered = try? theme.render(type: Self.self, context: context) {
            self.subject = rendered.subject
            self.plainTextBody = rendered.plainTextBody
            self.htmlBody = rendered.htmlBody
            
            let json: JSON = [
                "notifications": try! JSON(encodable: self.notifications)
            ]
            
            var friendlyMailHeaders = [
                HeaderKeyValue(key: HeaderKey.type.rawValue, value: FriendlyMailMessageType.notifications.rawValue),
            ]

            let base64JSONString = json.encodeAsBase64JSON()
            friendlyMailHeaders.append(HeaderKeyValue(key: HeaderKey.base64JSON.rawValue, base64JSONString))
            
            self.friendlyMailHeaders = friendlyMailHeaders
        } else {
            return nil
        }
    }
}

