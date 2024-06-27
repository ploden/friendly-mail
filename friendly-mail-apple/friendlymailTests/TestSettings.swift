//
//  TestSettings.swift
//  friendlymailTests
//
//  Created by Philip Loden on 3/12/22.
//

import Foundation
import friendlymail_core

struct TestSettings: Settings {
    var user: EmailAddress
    //var authState: OIDAuthState?
    var password: String?
    var selectedTheme: Theme
    public var isValid: Bool {
        return user.address.count > 0 && (password != nil)
    }
}
