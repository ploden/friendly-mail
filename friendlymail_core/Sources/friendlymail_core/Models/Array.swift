//
//  Array.swift
//  
//
//  Created by Philip Loden on 3/28/23.
//

import Foundation

public extension Array {
    func containsIdentifiable<T : Identifiable>(_ identifiable: T) -> Bool {
        let filtered = self.filter { ($0 as? T)?.id == identifiable.id }
        return filtered.count > 0
    }
}
