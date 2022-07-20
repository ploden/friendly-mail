//
//  Notification.swift
//  friendly-mail
//
//  Created by Philip Loden on 11/28/21.
//

import Foundation

enum NotificationType: String {
  case newPost = "new_post"
    case newComment = "new_comment"
    case newLike = "new_like"
}

protocol Notification {}
