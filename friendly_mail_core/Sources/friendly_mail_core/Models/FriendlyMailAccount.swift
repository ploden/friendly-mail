//
//  File.swift
//  
//
//  Created by Philip Loden on 11/14/22.
//

import Foundation

public struct FriendlyMailAccount {
    let user: Address
}

extension FriendlyMailAccount: Hashable {}
extension FriendlyMailAccount: Equatable {}
extension FriendlyMailAccount: Codable {}
