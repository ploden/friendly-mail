//
//  FriendlyMailAccount.swift
//  
//
//  Created by Philip Loden on 11/14/22.
//

import Foundation

public struct FriendlyMailAccount {
    let user: Address
    
    func getProfilePicURL(messageStore: MessageStore) -> URL? {
        let result = messageStore.commandResults(ofType: SetProfilePicSucceededCommandResult.self).last
        return result?.profilePicURL
    }
}

extension FriendlyMailAccount: Hashable {}
extension FriendlyMailAccount: Equatable {}
extension FriendlyMailAccount: Codable {}
