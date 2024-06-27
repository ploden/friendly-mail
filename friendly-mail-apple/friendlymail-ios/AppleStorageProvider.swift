//
//  AppleStorageProvider.swift
//  friendlymail-ios
//
//  Created by Philip Loden on 10/29/22.
//

import Foundation
import Amplify
import AWSS3StoragePlugin
import friendlymail_core

public class AppleStorageProvider: StorageProvider {
    var storageOperation: StorageUploadDataOperation?
    
    /*
    public static func uploadData(data: Data, to url: URL, contentType: String, completion: @escaping (Error?) -> ()) throws {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.uploadTask(with: request, from: data) { data, response, error in
            if let error = error {
                print ("error: \(error)")
                completion(error)
            } else if
                let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) == false
            {
                print ("server error")
                completion(NSError(domain: "fm", code: 1, userInfo: [:]))
            }
            completion(nil)
        }
        
        task.resume()
    }
     */
    
    public func uploadData(data: Data, filename: String, contentType: String, completion: @escaping (Error?, URL?) -> ()) {
        self.storageOperation = Amplify.Storage.uploadData(
            key: filename,
            data: data,
            progressListener: { progress in
                print("Progress: \(progress)")
            }, resultListener: { event in
                switch event {
                case .success(let data):
                    print("Completed: \(data)")
                    Amplify.Storage.getURL(key: filename, resultListener: { getURLResult in
                        switch event {
                        case let .success(url):
                            print("Completed: \(url)")
                            completion(nil, URL(string: url))
                        case let .failure(storageError):
                            print("Failed: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
                            completion(storageError, nil)
                            
                        }
                    })
                case .failure(let storageError):
                    print("Failed: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
                    completion(storageError, nil)
                }
            }
        )
    }
    
}
