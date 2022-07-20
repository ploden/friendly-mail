//
//  TestSettings.swift
//  friendly-mailTests
//
//  Created by Philip Loden on 3/12/22.
//

import Foundation
import friendly_mail_core

struct TestSettings: Settings {
    var user: Address
    //var authState: OIDAuthState?
    var password: String?
    var selectedTheme: Theme
    public var isValid: Bool {
        return user.address.count > 0 && (password != nil)
    }
}
