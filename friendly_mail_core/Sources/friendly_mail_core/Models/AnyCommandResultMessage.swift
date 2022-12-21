//
//  AnyCommandResultMessage.swift
//  
//
//  Created by Philip Loden on 12/19/22.
//

import Foundation

protocol AnyCommandResultMessage: BaseMessage {
    //var commandMessageID: MessageID { get }
    var commandResult: CommandResult { get }
}
