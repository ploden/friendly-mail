//
//  CommandResultsMessageProtocol.swift
//  
//
//  Created by Philip Loden on 12/19/22.
//

import Foundation

public protocol CommandResultsMessageProtocol: BaseMessageProtocol {
    var commandResults: [CommandResult] { get }
}
