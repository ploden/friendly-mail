//
//  AnyCommandResultMessage.swift
//  
//
//  Created by Philip Loden on 12/19/22.
//

import Foundation

public protocol AnyCommandResultsMessage: AnyBaseMessage {
    var commandResults: [any AnyCommandResult] { get }
}
