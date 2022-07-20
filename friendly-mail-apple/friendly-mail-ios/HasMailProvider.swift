//
//  HasMailProvider.swift
//  friendly-mail
//
//  Created by Philip Loden on 2/3/22.
//

import Foundation

public protocol HasMailProvider {
    var mailProvider: MailProvider! { get set }
 }
