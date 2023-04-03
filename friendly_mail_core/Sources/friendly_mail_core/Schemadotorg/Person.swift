//
//  File.swift
//  
//
//  Created by Philip Loden on 4/27/22.
//

import Foundation
import Stencil

final class Person: Thing, DynamicMemberLookup {
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
    
    public subscript(dynamicMember member: String) -> Any? {
        if member == "displayName" {
            return displayName
        } else if member == "email" {
            return email
        }
        return nil
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

extension Person: Identifiable {
    public var id: String {
        return email
    }
}
