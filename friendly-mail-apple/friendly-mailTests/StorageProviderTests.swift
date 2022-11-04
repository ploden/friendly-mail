//
//  StorageProviderTests.swift
//  friendly-mail-ios-Tests
//
//  Created by Philip Loden on 10/31/22.
//

import XCTest
@testable import Amplify
@testable import friendly_mail_ios
@testable import friendly_mail_core

class StorageProviderTests: XCTestCase {
    
    func testUploadFile() throws {
        /*
         
         let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast1,
         identityPoolId:"us-east-1:c1b1ef96-1dcd-42a9-9cbb-034006519ad3")
         
         let configuration = AWSServiceConfiguration(region:.USEast1, credentialsProvider:credentialsProvider)
         
         AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
         */
        
        //let testUUID = "5BE644EE-69B1-4DF4-8688-6E678C2DDD29"
        
        let profilePicPath = Bundle(for: type(of: self )).path(forResource: "phil_profile_pic_attachment", ofType: "jpeg")!
        let profilePicURL = URL(fileURLWithPath: profilePicPath)
        let profilePicData = try! Data(contentsOf: profilePicURL)
        
        let url = URL(string: "https://friendly-mail-1.s3.amazonaws.com/phil_profile_pic_attachment.jpeg")!
        
        let expectation = XCTestExpectation(description: "Wait for upload.")
        
        try! StorageProvider.uploadData(data: profilePicData, to: url, contentType: "image/jpeg") { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        let _ = XCTWaiter.wait(for: [expectation], timeout: 10.0)
        
        //try! StorageProvider.uploadFile(bucket: "friendly-mail-1", key: "", file: "")
    }
    
}
