//
//  NewPostNotification.swift
//  friendly-mail
//
//  Created by Philip Loden on 11/29/21.
//

import Foundation
import SerializedSwift
import Stencil

public class NewPostingNotification: Notification {
    @Serialized
    var createPostingMessageID: MessageID
    
    public override subscript(dynamicMember member: String) -> Any? {
        if member == "notificationType" {
            return notificationType
        }
        else if member == "createPostingMessageID" {
            return createPostingMessageID
        }
        return nil
    }
    
    public required init() {
        super.init()
        self.notificationType = .newPost
        self.createPostingMessageID = ""
    }
    
    public init(createPostingMessageID: MessageID) {
        super.init()
        self.notificationType = .newPost
        self.createPostingMessageID = createPostingMessageID
    }
    
    override public func hash(into hasher: inout Hasher) {
        hasher.combine(notificationType)
        hasher.combine(createPostingMessageID)
    }
}

public extension NewPostingNotification {
    static func == (lhs: NewPostingNotification, rhs: NewPostingNotification) -> Bool {
        return lhs.createPostingMessageID == rhs.createPostingMessageID &&
        lhs.notificationType == rhs.notificationType
    }
}
