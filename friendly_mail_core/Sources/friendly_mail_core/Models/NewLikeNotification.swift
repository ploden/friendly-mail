//
//  NewLikeNotification.swift
//  friendly-mail
//
//  Created by Philip Loden on 8/23/21.
//

import Foundation
import SerializedSwift
import Stencil

public class NewLikeNotification: Notification {
    @Serialized
    var createLikeMessageID: MessageID
    
    public override subscript(dynamicMember member: String) -> Any? {
        if member == "notificationType" {
            return notificationType
        }
        else if member == "createLikeMessageID" {
            return createLikeMessageID
        }
        return super[dynamicMember: member]
    }
    
    public required init() {
        super.init()
        self.notificationType = .newLike
        self.createLikeMessageID = ""
    }
    
    public init(createLikeMessageID: MessageID) {
        super.init()
        self.notificationType = .newLike
        self.createLikeMessageID = createLikeMessageID
    }
    
    override public func hash(into hasher: inout Hasher) {
        hasher.combine(notificationType)
        hasher.combine(createLikeMessageID)
    }
}

public extension NewLikeNotification {
    static func == (lhs: NewLikeNotification, rhs: NewLikeNotification) -> Bool {
        return lhs.createLikeMessageID == rhs.createLikeMessageID &&
        lhs.notificationType == rhs.notificationType
    }
}
