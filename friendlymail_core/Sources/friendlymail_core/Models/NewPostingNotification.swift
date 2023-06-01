//
//  NewPostNotification.swift
//  friendlymail
//
//  Created by Philip Loden on 11/29/21.
//

import Foundation
import SerializedSwift
import Stencil

public class NewPostingNotification: Notification {
    @Serialized
    var createPostingMessageID: MessageID
    
    public required init() {
        super.init()
        self.notificationType = .newPost
        self.createPostingMessageID = ""
    }
    
    public init(follow: UserFollow, createPostingMessageID: MessageID) {
        super.init()
        self.notificationType = .newPost
        self.follow = follow
        self.createPostingMessageID = createPostingMessageID
    }
    
    override public func hash(into hasher: inout Hasher) {
        hasher.combine(notificationType)
        hasher.combine(createPostingMessageID)
        hasher.combine(follow)
        hasher.combine(createRelatedContentMessageID)
    }
}

public extension NewPostingNotification {
    static func == (lhs: NewPostingNotification, rhs: NewPostingNotification) -> Bool {
        return lhs.createPostingMessageID == rhs.createPostingMessageID &&
        lhs.notificationType == rhs.notificationType &&
        lhs.follow == rhs.follow &&
        lhs.createRelatedContentMessageID == rhs.createRelatedContentMessageID
    }
}
