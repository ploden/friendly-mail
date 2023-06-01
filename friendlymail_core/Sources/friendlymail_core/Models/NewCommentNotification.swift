//
//  NewCommentNotification.swift
//  friendlymail
//
//  Created by Philip Loden on 12/13/21.
//

import Foundation
import SerializedSwift
import Stencil

public class NewCommentNotification: Notification {
    @Serialized
    var createCommentMessageID: MessageID        
    
    public required init() {
        super.init()
        self.notificationType = .newComment
        self.createCommentMessageID = ""
    }
    
    public init(follow: UserFollow, createCommentMessageID: MessageID) {
        super.init()
        self.follow = follow
        self.notificationType = .newComment
        self.createCommentMessageID = createCommentMessageID
    }
    
    public override func hash(into hasher: inout Hasher) {
        hasher.combine(notificationType)
        hasher.combine(createCommentMessageID)
        hasher.combine(follow)
        hasher.combine(createRelatedContentMessageID)
    }
}

public extension NewCommentNotification {
    static func == (lhs: NewCommentNotification, rhs: NewCommentNotification) -> Bool {
        return lhs.createCommentMessageID == rhs.createCommentMessageID &&
        lhs.notificationType == rhs.notificationType &&
        lhs.follow == rhs.follow &&
        lhs.createRelatedContentMessageID == rhs.createRelatedContentMessageID
    }
}
