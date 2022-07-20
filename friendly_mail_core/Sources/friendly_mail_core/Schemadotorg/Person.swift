//
//  File.swift
//  
//
//  Created by Philip Loden on 4/27/22.
//

import Foundation

final class Person: Thing {
    let email: String
    let familyName: String?
    let givenName: String?
    let additionalName: String?
    
    public var displayName: String? {
        get {
            if
                let givenName = givenName,
                givenName.count > 0,
                let familyName = familyName,
                familyName.count > 0
            {
                return "\(givenName) \(familyName)"
            }
            else
            {
                return email
            }
        }
    }

    init(email: String) {
        self.email = email
        self.familyName = nil
        self.givenName = nil
        self.additionalName = nil
    }
}

extension Person: Codable {}

extension Person: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(email)
    }
}

extension Person: Equatable {
    public static func ==(lhs: Person, rhs: Person) -> Bool {
        return lhs.email == rhs.email
    }
}
