//
//  DictionaryCodable.swift
//  friendlymail
//
//  Created by Philip Loden on 10/11/21.
//

import Foundation

public protocol DictionaryEncodable {
    func encode() throws -> Any
}

public extension DictionaryEncodable where Self: Encodable {
    func encode() throws -> Any {
        let jsonData = try JSONEncoder().encode(self)
        return try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments)
    }
}

public protocol DictionaryDecodable {
    static func decode(_ dictionary: Any) throws -> Self
}

public extension DictionaryDecodable where Self: Decodable {
    static func decode(_ dictionary: Any) throws -> Self {
        let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])
        return try JSONDecoder().decode(Self.self, from: jsonData)
    }
}

public typealias DictionaryCodable = DictionaryEncodable & DictionaryDecodable
