//
//  Base64JSONCodable.swift
//  
//
//  Created by Philip Loden on 1/17/23.
//

import Foundation
import GenericJSON

public protocol Base64JSONCodable {
    func encodeAsBase64JSON() -> String
    static func decode(fromBase64JSON base64JSON: String) -> Self?
    static func jsonKey() -> String
    func jsonKey() -> String
}

extension Base64JSONCodable where Self: Codable {
    public static func decode(fromBase64JSON base64JSON: String) -> Self? {
        let decoder = JSONDecoder()
        
        if
            let decodedData = Data(base64Encoded: base64JSON.paddedForBase64Decoding, options: .ignoreUnknownCharacters),
            let decodedDataString = String(data: decodedData, encoding: .utf8),
            let jsonData = decodedDataString.data(using: .utf8),
            let result = try? decoder.decode(Self.self, from: jsonData)
        {
            return result
        }
        return nil
    }
    
    public func encodeAsBase64JSON() -> String {
        let jsonData = try! JSONEncoder().encode(self)
        let base64JSONString = jsonData.base64EncodedString()
        return base64JSONString
    }
    
    public static func jsonKey() -> String {
        let key = String(describing: self).split(separator: ".").last!
        let capitalized: String = key.prefix(1).lowercased() + key.dropFirst()
        return capitalized
    }
    
    public func jsonKey() -> String {
        return type(of: self).jsonKey()
    }
}

extension JSON: Base64JSONCodable {}
