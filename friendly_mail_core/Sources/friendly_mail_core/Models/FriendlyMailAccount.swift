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
        let message = messageStore.allMessages.first { $0.header.sender == user && $0 is SetProfilePicSucceededCommandResultMessage } as? SetProfilePicSucceededCommandResultMessage
        return message?.setProfilePicSucceededCommandResult.profilePicURL
    }
}

extension FriendlyMailAccount: Hashable {}
extension FriendlyMailAccount: Equatable {}
extension FriendlyMailAccount: Codable {}
