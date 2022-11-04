//
//  File.swift
//  
//
//  Created by Philip Loden on 10/25/22.
//

import Foundation

public struct Attachment {
    let mimeType: String
    let data: Data
    let filename: String?
    
    public init(mimeType: String, data: Data, filename: String?) {
        self.mimeType = mimeType
        self.data = data
        self.filename = filename
    }
}

extension Attachment: Codable {}

extension Attachment: Hashable {}
