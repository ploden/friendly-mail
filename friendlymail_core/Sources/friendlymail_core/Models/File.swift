//
//  File.swift
//  
//
//  Created by Philip Loden on 4/17/23.
//

import Foundation
import SerializedSwift

struct CreateLikeAction: Serializable {
    init() {
        self.parentItemMessageID = MessageID()
    }
    
    init(parentItemMessageID: MessageID) {
        self.parentItemMessageID = parentItemMessageID
    }
    
    @Serialized
    public var parentItemMessageID: MessageID // id of create posting message that we're liking 
}

struct CreateCommentAction: Serializable {
    init() {
        self.parentItemMessageID = MessageID()
    }
    
    init(parentItemMessageID: MessageID) {
        self.parentItemMessageID = parentItemMessageID
    }
    
    @Serialized
    public var parentItemMessageID: MessageID // id of create posting message that we're commenting on
}
