//
//  Follow.swift
//  friendlymail
//
//  Created by Philip Loden on 11/24/21.
//

import Foundation
import SerializedSwift
import Stencil

public enum UpdateFrequency: String, Codable, Hashable, Equatable {
    case realtime = "realtime"
}

public protocol AnyFollow {
    var followerID: ID { get }
    var followeeID: ID { get }
}

public struct PostingFollow: AnyFollow, Serializable {
    @Serialized
    public var followerID: PersonID
    @Serialized
    public var followeeID: PostingID
    @Serialized
    var frequency: UpdateFrequency
    @Serialized
    var messageID: MessageID // ID of the message that created this follow
    
    public init() {
        self.followerID = ""
        self.followeeID = ""
        self.frequency = .realtime
        self.messageID = ""
    }
}

extension PostingFollow: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(followerID)
        hasher.combine(followeeID)
        hasher.combine(frequency)
        hasher.combine(messageID)
    }
}

extension PostingFollow: Equatable {
    public static func == (lhs: PostingFollow, rhs: PostingFollow) -> Bool {
        return lhs.followerID == rhs.followerID &&
        lhs.followeeID == rhs.followeeID &&
        lhs.frequency == rhs.frequency &&
        lhs.messageID == rhs.messageID
    }
}

public struct UserFollow: AnyFollow, Equatable, Hashable, Serializable {
    @Serialized
    public var followerID: PersonID
    @Serialized
    public var followeeID: PersonID
    @Serialized
    var frequency: UpdateFrequency
    @Serialized
    var messageID: MessageID // ID of the message that created this follow
    
    public init() {
        self.followerID = ""
        self.followeeID = ""
        self.frequency = .realtime
        self.messageID = ""
    }

    public init(followerID: PersonID, followeeID: PersonID, frequency: UpdateFrequency, messageID: MessageID) {
        self.followerID = followerID
        self.followeeID = followeeID
        self.frequency = frequency
        self.messageID = messageID
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(followerID)
        hasher.combine(followeeID)
        hasher.combine(frequency)
        hasher.combine(messageID)
    }
}

extension UserFollow: Codable {}

public extension UserFollow {
    static func == (lhs: UserFollow, rhs: UserFollow) -> Bool {
        return lhs.followerID == rhs.followerID &&
        lhs.followeeID == rhs.followeeID &&
        lhs.frequency == rhs.frequency &&
        lhs.messageID == rhs.messageID
    }
}

extension UserFollow: Identifiable {
    public var id: String {
        return messageID
    }
}
