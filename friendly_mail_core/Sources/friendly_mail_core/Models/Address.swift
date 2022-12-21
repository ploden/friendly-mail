//
//  Address.swift
//  friendly-mail
//
//  Created by Philip Loden on 7/27/21.
//

import Foundation

public struct Address {
    public let name: String?
    public let givenName: String?
    public let familyName: String?
    public let address: String
    public var displayName: String {
        get {
            if
                let name = name,
                name.count > 0
            {
                return name
            }
            else if
                let givenName = givenName,
                givenName.count > 0,
                let familyName = familyName,
                familyName.count > 0
            {
                return "\(givenName) \(familyName)"
            }
            else
            {
                return address
            }
        }
    }

    public init(address: String) {
        self.name = nil
        self.givenName = nil
        self.familyName = nil
        self.address = address
    }
    
    public init?(name: String?, address: String?) {
        if let address = address {
            self.name = name
            self.givenName = nil
            self.familyName = nil
            self.address = address
        } else {
            return nil
        }
    }
    
    public init?(name: String?, givenName: String?, familyName: String?, address: String?) {
        if let address = address {
            self.name = name
            self.givenName = givenName
            self.familyName = familyName
            self.address = address
        } else {
            return nil
        }
    }
    
    static func isNameValid(name: String?, givenName: String?, familyName: String?) -> Bool {
        if
            let name = name,
            name.count > 0
        {
            return true
        }
        else if
            let givenName = givenName,
            givenName.count > 0,
            let familyName = familyName,
            familyName.count > 0
        {
            return true
        }
        else
        {
            return false
        }
    }
}

extension Address: Codable {}
extension Address: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(address)
    }
}
extension Address: Equatable {
    public static func ==(lhs: Address, rhs: Address) -> Bool {
        return lhs.address == rhs.address
    }
}
extension Address: Identifiable {
    public var identifier: MessageID {
        return address
    }
}
