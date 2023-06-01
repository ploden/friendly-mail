//
//  NotificationsMessageDraftTests.swift
//  friendlymail-ios-Tests
//
//  Created by Philip Loden on 4/18/23.
//

import XCTest
@testable import friendlymail_core

final class NotificationsMessageDraftTests: XCTestCase {

    func testSubjectBase64JSON() throws {
        let messageID = "xyz@gmail.com"
        let subjectJSON = NotificationsMessageDraft.subjectBase64JSON(parentItemMessageID: messageID)
        
        XCTAssertFalse(subjectJSON.like.isEmpty)
        let likeSubject = "Fm Like \(subjectJSON.like)"
        let likeAction = MessageFactory.extractCreateLikeAction(subject: likeSubject)
        XCTAssertEqual(likeAction?.parentItemMessageID, messageID)
        
        XCTAssertFalse(subjectJSON.comment.isEmpty)
        let commentSubject = "Fm Comment \(subjectJSON.comment)"
        let commentAction = MessageFactory.extractCreateCommentAction(subject: commentSubject)
        XCTAssertEqual(commentAction?.parentItemMessageID, messageID)
    }

}
