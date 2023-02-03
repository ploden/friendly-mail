//
//  TestStorageProvider.swift
//  friendly-mail-ios-Tests
//
//  Created by Philip Loden on 1/13/23.
//

import XCTest
@testable import friendly_mail_ios
@testable import friendly_mail_core

class TestStorageProvider: StorageProvider {
    func uploadData(data: Data, filename: String, contentType: String, completion: @escaping (Error?, URL?) -> ()) {
        let url = URL(string: "http://test.com/\(filename)")
        completion(nil, url)
    }    
}
