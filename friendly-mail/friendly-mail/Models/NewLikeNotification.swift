//
//  NewLikeNotification.swift
//  friendly-mail
//
//  Created by Philip Loden on 8/23/21.
//

import Foundation

struct NewLikeNotification: Notification {
    let notificationType = NotificationType.newLike
    let createLikeMessageID: MessageID
}

extension NewLikeNotification: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(notificationType)
        hasher.combine(createLikeMessageID)
    }
}
