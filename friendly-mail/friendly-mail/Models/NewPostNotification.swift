//
//  NewPostNotification.swift
//  friendly-mail
//
//  Created by Philip Loden on 11/29/21.
//

import Foundation

struct NewPostNotification: Notification {
    let notificationType = NotificationType.newPost    
    let createPostMessageID: MessageID
}
