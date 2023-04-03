//
//  NewCommentNotification.swift
//  friendly-mail
//
//  Created by Philip Loden on 12/13/21.
//

import Foundation
import SerializedSwift
import Stencil

public class NewCommentNotification: Notification {
    @Serialized
    var createCommentMessageID: MessageID
    
    public override subscript(dynamicMember member: String) -> Any? {
        if member == "notificationType" {
            return notificationType
        }
        else if member == "createCommentMessageID" {
            return createCommentMessageID
        }
        return super[dynamicMember: member]
    }
    
    public required init() {
        super.init()
        self.notificationType = .newComment
        self.createCommentMessageID = ""
    }
    
    public init(createCommentMessageID: MessageID) {
        super.init()
        self.notificationType = .newComment
        self.createCommentMessageID = createCommentMessageID
    }
    
    public override func hash(into hasher: inout Hasher) {
        hasher.combine(notificationType)
        hasher.combine(createCommentMessageID)
    }
}

public extension NewCommentNotification {
    static func == (lhs: NewCommentNotification, rhs: NewCommentNotification) -> Bool {
        return lhs.createCommentMessageID == rhs.createCommentMessageID &&
        lhs.notificationType == rhs.notificationType
    }
}
