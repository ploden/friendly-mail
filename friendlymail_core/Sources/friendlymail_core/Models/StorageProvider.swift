//
//  StorageProvider.swift
//  
//
//  Created by Philip Loden on 1/2/23.
//

import Foundation

public protocol StorageProvider {
    func uploadData(data: Data, filename: String, contentType: String, completion: @escaping (Error?, URL?) -> ())
}
