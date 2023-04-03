//
//  Notification.swift
//  friendly-mail
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

public class Notification: Equatable, Hashable, Serializable, DynamicMemberLookup {
    @Serialized
    var notificationType: NotificationType
    @Serialized
    var follow: Follow // the follow related to this notification 
    @Serialized
    var createRelatedContentMessageID: MessageID
    
    public subscript(dynamicMember member: String) -> Any? {
        if member == "notificationType" {
            return notificationType
        }
        return nil
    }
    
    required public init() {
        notificationType = .undefined
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(notificationType)
    }
}

public extension Notification {
    static func == (lhs: Notification, rhs: Notification) -> Bool {
        return lhs.notificationType == rhs.notificationType
    }
    
}
