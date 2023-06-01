//
//  EmailAddress.swift
//  friendlymail
//
//  Created by Philip Loden on 7/27/21.
//

import Foundation
import RegexBuilder
import SerializedSwift
import Stencil

public struct EmailAddress: Serializable {
    @Serialized
    public var address: String
    @Serialized
    public var displayName: String?
    static var nullAddress = "null@null.com"        
    
    public init() {
        
    }
    
    public init?(displayName: String? = nil, address: String?) {
        guard
            let address = address,
            address.isValidEmail()
        else {
            return nil
        }
        self.address = address
        self.displayName = displayName
    }
        
}

extension EmailAddress: Codable {}

extension EmailAddress: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(address)
    }
}

extension EmailAddress: Equatable {
    public static func ==(lhs: EmailAddress, rhs: EmailAddress) -> Bool {
        return lhs.address == rhs.address
    }
}

extension EmailAddress: Identifiable {
    public var id: String {
        get {
            return address
        }
    }
}

/*
extension String {
    func isValidEmail() -> Bool {
        let word = OneOrMore(.word)
        
        let emailPattern = Regex {
            Capture {
                ZeroOrMore {
                    word
                    "."
                }
                word
            }
            "@"
            Capture {
                word
                OneOrMore {
                    "."
                    word
                }
            }
        }

        let text = "My email is my.name@example.com."
        if let match = self.firstMatch(of: emailPattern) {
            let (wholeMatch, name, domain) = match.output
            // wholeMatch is "my.name@example.com"
            // name is "my.name"
            // domain is "example.com"
        }
    }
}
*/
