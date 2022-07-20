//
//  NewCommentNotification.swift
//  friendly-mail
//
//  Created by Philip Loden on 12/13/21.
//

import Foundation

public struct NewCommentNotification: Notification {
    let notificationType = NotificationType.newComment
    let createCommentMessageID: MessageID
}

extension NewCommentNotification: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(notificationType)
        hasher.combine(createCommentMessageID)
    }
}
