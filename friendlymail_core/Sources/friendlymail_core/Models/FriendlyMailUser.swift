//
//  FriendlyMailAccount.swift
//  
//
//  Created by Philip Loden on 11/14/22.
//

import Foundation

public class FriendlyMailUser: Person {
    
    public required init() {
        super.init(email: EmailAddress())
    }
    
    override init(email: EmailAddress, familyName: String? = nil, givenName: String? = nil, additionalName: String? = nil) {
        super.init(email: email, familyName: familyName, givenName: givenName, additionalName: additionalName)
    }
    
    public required convenience init(from decoder: Decoder) throws {
        let person = try Person.init(from: decoder)
        self.init(email: person.email, familyName: person.familyName, givenName: person.givenName, additionalName: person.additionalName)
    }
    
    func getProfilePicURL(messageStore: MessageStore) -> URL? {
        let result = messageStore.commandResults(ofType: SetProfilePicSucceededCommandResult.self).last
        return result?.profilePicURL
    }
    
}
