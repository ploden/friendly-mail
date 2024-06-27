//
//  NewPostNotificationContext.swift
//  
//
//  Created by Philip Loden on 4/19/23.
//

import Foundation

public protocol Context: DictionaryEncodable {}

public protocol NotificationContext: Context {
    var notificationType: String { get }
}

public struct NotificationsMessageContext: Context {
    private enum CodingKeys: String, CodingKey {
            case signature, notificationContexts, firstNotificationContext
        }
    
    public func encode() throws -> Any {
        let notifications = notificationContexts.compactMap { try? $0.encode() }
        let postingAuthorDisplayName = {
            if let name = (firstNotificationContext as? NewPostNotificationContext)?.createPostMessagePostingAuthorDisplayName {
                return name
            } else {
                return (firstNotificationContext as! NewCommentNotificationContext).createPostMessagePostingAuthorDisplayName
            }
        }
        let dict: [String : Any] = [
            CodingKeys.notificationContexts.rawValue: notifications,
            CodingKeys.signature.rawValue: signature,
            "firstNotificationNotificationType": firstNotificationContext.notificationType,
            "firstNotificationPostingAuthorDisplayName": postingAuthorDisplayName,
            CodingKeys.firstNotificationContext.rawValue: firstNotificationContext
        ]
        return dict
    }
    
    var notificationContexts: [NotificationContext]
    var signature: String
    var firstNotificationContext: NotificationContext
}

public struct NewPostNotificationContext: NotificationContext & Encodable {
    public var notificationType: String
    var likeSubjectBase64JSON: String
    var commentSubjectBase64JSON: String
    var createPostMessagePostingAuthorDisplayName: String
    var createPostMessagePostingAuthorID: ID
    var createPostMessagePostingArticleBody: String
    var createPostMessagePostingAuthorEmailAddress: String
    var notificationFollowFollowerID: ID
    var likeBody: String
}

public struct NewCommentNotificationContext: NotificationContext & Encodable {
    public var notificationType: String
    var likeSubjectBase64JSON: String
    var commentSubjectBase64JSON: String
    var createPostMessagePostingAuthorDisplayName: String
    var createPostMessagePostingAuthorID: ID
    var createPostMessagePostingArticleBody: String
    var notificationFollowFollowerID: ID
    var likeBody: String
    var createCommentMessagePostingAuthorEmailAddress: String
    var createCommentMessagePostingArticleBody: String
}

public struct NewLikeNotificationContext: NotificationContext & Encodable {
    public var notificationType: String
    var createPostMessagePostingAuthorDisplayName: String
    var createPostMessagePostingAuthorID: ID
    var createPostMessagePostingArticleBody: String
    var notificationFollowFollowerID: ID
    var likeBody: String
    var createLikeMessagePostingAuthorEmailAddress: String
    var createLikeMessagePostingAuthorDisplayName: String
    var createLikeMessagePostingArticleBody: String
}

public struct CommandResultContext: Context & Encodable {
    var commandInput: String
    var message: String
}

public struct CommandResultMessageContext: Context & Encodable {    
    var firstCommandResultContext: CommandResultContext
    var signature: String
}
