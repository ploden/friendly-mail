//
//  Address.swift
//  friendly-mail
//
//  Created by Philip Loden on 7/27/21.
//

import Foundation

struct Address {
    let name: String?
    let givenName: String?
    let familyName: String?
    let address: String

    init?(name: String?, address: String?) {
        if let address = address {
            self.name = name
            self.givenName = nil
            self.familyName = nil
            self.address = address
        } else {
            return nil
        }
    }
    
    init?(name: String?, givenName: String?, familyName: String?, address: String?) {
        if let address = address {
            self.name = name
            self.givenName = givenName
            self.familyName = familyName
            self.address = address
        } else {
            return nil
        }
    }
}

extension Address: Codable {}
extension Address: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(address)
    }
}
extension Address: Equatable {
    static func ==(lhs: Address, rhs: Address) -> Bool {
        return lhs.address == rhs.address
    }
}
extension Address: Identifiable {
    var identifier: MessageID {
        return address
    }
}
