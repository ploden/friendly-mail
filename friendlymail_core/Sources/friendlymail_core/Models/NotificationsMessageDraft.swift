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
    
    var to: [EmailAddress]
    
    var subject: String
    
    var htmlBody: String?
    
    var plainTextBody: String
    
    var friendlyMailHeaders: [HeaderKeyValue]?
    
    init?(to: [EmailAddress], notifications: [Notification], theme: Theme, messages: MessageStore) {
        guard to.count > 0 && notifications.count > 0 else {
            return nil
        }
        
        self.to = to
        self.notifications = notifications
    
        let combined: [NotificationContext] = notifications.compactMap {
                switch $0.notificationType {
                case .newLike:
                    if
                        let newLikeNotification = $0 as? NewLikeNotification,
                        let createLikeMessage = messages.getMessage(for: newLikeNotification.createLikeMessageID) as? CreateLikeMessage,
                        let createPostMessage = messages.getMessage(for: createLikeMessage.like.parentItemMessageID) as? CreatePostingMessage
                    {
                        let context = NewLikeNotificationContext(
                            notificationType: newLikeNotification.notificationType.rawValue,
                            createPostMessagePostingAuthorDisplayName: createPostMessage.posting.author.displayName,
                            createPostMessagePostingAuthorID: createPostMessage.posting.author.id,
                            createPostMessagePostingArticleBody: createPostMessage.posting.articleBody,
                            notificationFollowFollowerID: newLikeNotification.follow.followerID,
                            likeBody: Template.PlainText.like.rawValue,
                            createLikeMessagePostingAuthorEmailAddress: createLikeMessage.post.author.email.address,
                            createLikeMessagePostingAuthorDisplayName: createLikeMessage.post.author.displayName,
                            createLikeMessagePostingArticleBody: createLikeMessage.post.articleBody
                        )
                        
                        return context
                    }
                case .newComment:
                    if
                        let newCommentNotification = $0 as? NewCommentNotification,
                        let createCommentMessage = messages.getMessage(for: newCommentNotification.createCommentMessageID) as? CreateCommentMessage,
                        let createPostMessage = messages.getMessage(for: createCommentMessage.comment.parentItemID) as? CreatePostingMessage
                    {
                        let likeCommentSubject = Self.subjectBase64JSON(parentItemMessageID: createPostMessage.header.messageID)

                        let context = NewCommentNotificationContext(
                            notificationType: newCommentNotification.notificationType.rawValue,
                            likeSubjectBase64JSON: likeCommentSubject.like,
                            commentSubjectBase64JSON: likeCommentSubject.comment,
                            createPostMessagePostingAuthorDisplayName: createPostMessage.posting.author.displayName,
                            createPostMessagePostingAuthorID: createPostMessage.posting.author.id,
                            createPostMessagePostingArticleBody: createPostMessage.posting.articleBody,
                            notificationFollowFollowerID: newCommentNotification.follow.followerID,
                            likeBody: Template.PlainText.like.rawValue,
                            createCommentMessagePostingAuthorEmailAddress: createCommentMessage.posting.author.email.address,
                            createCommentMessagePostingArticleBody: createCommentMessage.posting.articleBody
                        )
                        
                        return context
                    }
                case .newPost:
                    if
                        let newPostNotification = $0 as? NewPostingNotification,
                        let createPostMessage = messages.getMessage(for: newPostNotification.createPostingMessageID) as? CreatePostingMessage
                    {
                        let likeCommentSubject = Self.subjectBase64JSON(parentItemMessageID: newPostNotification.createPostingMessageID)

                        let context = NewPostNotificationContext(
                            notificationType: newPostNotification.notificationType.rawValue,
                            likeSubjectBase64JSON: likeCommentSubject.like,
                            commentSubjectBase64JSON: likeCommentSubject.comment,
                            createPostMessagePostingAuthorDisplayName: createPostMessage.posting.author.displayName,
                            createPostMessagePostingAuthorID: createPostMessage.posting.author.id,
                            createPostMessagePostingArticleBody: createPostMessage.posting.articleBody,
                            createPostMessagePostingAuthorEmailAddress: createPostMessage.posting.author.email.address,
                            notificationFollowFollowerID: newPostNotification.follow.followerID,
                            likeBody: Template.PlainText.like.rawValue
                        )
                        
                        return context
                    }
                default:
                    return nil
                }
            return nil
        }

        let context = NotificationsMessageContext(
            notificationContexts: combined,
            signature: "\(Template.PlainText.signature.rawValue)",
            firstNotificationContext: combined.first!
        )

        let contextAny = try? context.encode()
        let contextDict = contextAny as! [String : Any]
        
        if let rendered = try? theme.render(type: Self.self, context: contextDict) {
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
    
    static func subjectBase64JSON(parentItemMessageID: MessageID) -> (like: String, comment: String) {
        let likeAction = CreateLikeAction(parentItemMessageID: parentItemMessageID)
        
        let likeSubjectJSON: JSON = [
            "like": try! JSON(encodable: likeAction)
        ]
        
        let likeSubjectBase64JSONString = likeSubjectJSON.encodeAsBase64JSON()
        
        let commentAction = CreateCommentAction(parentItemMessageID: parentItemMessageID)
        
        let commentSubjectJSON: JSON = [
            "comment": try! JSON(encodable: commentAction)
        ]
        
        let commentSubjectBase64JSONString = commentSubjectJSON.encodeAsBase64JSON()
        
        return (likeSubjectBase64JSONString, commentSubjectBase64JSONString)
    }
}

