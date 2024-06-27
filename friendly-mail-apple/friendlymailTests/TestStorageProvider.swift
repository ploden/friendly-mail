//
//  TestStorageProvider.swift
//  friendlymail-ios-Tests
//
//  Created by Philip Loden on 1/13/23.
//

import XCTest
@testable import friendlymail_ios
@testable import friendlymail_core

class TestStorageProvider: StorageProvider {
    func uploadData(data: Data, filename: String, contentType: String, completion: @escaping (Error?, URL?) -> ()) {
        let url = URL(string: "http://test.com/\(filename)")
        completion(nil, url)
    }    
}
