//
//  AnyMessageDraft.swift
//  
//
//  Created by Philip Loden on 2/9/23.
//

import Foundation

public protocol AnyMessageDraft {
    var to: [EmailAddress] { get }
    var subject: String { get }
    var htmlBody: String? { get }
    var plainTextBody: String { get }
    var friendlyMailHeaders: [HeaderKeyValue]? { get }
}
