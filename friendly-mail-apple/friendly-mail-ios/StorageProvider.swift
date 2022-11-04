//
//  StorageProvider.swift
//  friendly-mail-ios
//
//  Created by Philip Loden on 10/29/22.
//

import Foundation
import Amplify
import AWSS3StoragePlugin

public struct StorageProvider {
    
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
    
}
