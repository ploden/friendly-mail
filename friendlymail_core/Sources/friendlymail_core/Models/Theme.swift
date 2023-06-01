//
//  Theme.swift
//  friendlymail
//
//  Created by Philip Loden on 2/11/22.
//

import Foundation
import Stencil
import PathKit

public struct Theme: Equatable {
    public let name: String
    let directory: String
    
    func render(type: AnyMessageDraft.Type, context: [String:Any]) throws -> (subject: String, plainTextBody: String, htmlBody: String?) {
        let dir = String(describing: type)
        let inDirectory = "\(directory)/\(dir)"
                        
        let environment = Environment(loader: FileSystemLoader(bundle: [Bundle.module]), trimBehaviour: .smart)
                        
        let subject = try! environment.renderTemplate(name: "\(inDirectory)/subject.txt", context: context)
        let plainTextBody = try! environment.renderTemplate(name: "\(inDirectory)/plain_text_body.txt", context: context)
        
        assert(subject.count > 0)
        
        return (subject, plainTextBody, nil)
    }
    
    func renderTemplate(name: String, context: [String:Any]) throws -> String {
        let environment = Environment(loader: FileSystemLoader(bundle: [Bundle.module]))
        let result = try! environment.renderTemplate(name: name, context: context)
        return result
    }
    
}

extension Theme: Codable {}

extension Theme: Identifiable {
    public var id: String {
        return name
    }
}
