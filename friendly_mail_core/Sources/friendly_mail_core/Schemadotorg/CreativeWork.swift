//
//  CreativeWork.swift
//  
//
//  Created by Philip Loden on 4/23/22.
//

import Foundation

protocol CreativeWork: Thing {
    var author: Person { get }
    var dateCreated: Date { get }
}
