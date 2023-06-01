//
//  Notification.swift
//  friendlymail
//
//  Created by Philip Loden on 11/28/21.
//

import Foundation
import SerializedSwift
import Stencil

enum NotificationType: String, Codable {
    case newPost = "new_post"
    case newComment = "new_comment"
    case newLike = "new_like"
    case undefined = "undefined"
}

public class Notification: Equatable, Hashable, Serializable {
    @Serialized
    var notificationType: NotificationType
    @Serialized
    var follow: UserFollow // the follow related to this notification 
    @Serialized
    var createRelatedContentMessageID: MessageID
    
    required public init() {
        notificationType = .undefined
        follow = UserFollow(followerID: "", followeeID: "", frequency: .realtime, messageID: "")
        createRelatedContentMessageID = ""
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(notificationType)
        hasher.combine(follow)
        hasher.combine(createRelatedContentMessageID)
    }
}

public extension Notification {
    static func == (lhs: Notification, rhs: Notification) -> Bool {
        return lhs.notificationType == rhs.notificationType &&
        lhs.follow == rhs.follow &&
        lhs.createRelatedContentMessageID == rhs.createRelatedContentMessageID
    }
    
}
