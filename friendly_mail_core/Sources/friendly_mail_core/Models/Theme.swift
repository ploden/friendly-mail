//
//  Theme.swift
//  friendly-mail
//
//  Created by Philip Loden on 2/11/22.
//

import Foundation
import Stencil
import PathKit

public struct Theme: Equatable {
    public let name: String
    let directory: String
    
    func render(type: AnyMessageDraft.Type, context: [String:Any]) throws -> (subject: String, plainTextBody: String, htmlBody: String) {
        /*
        let context = [
          "message": message
        ]
         */

        let dir = String(describing: type)
        let inDirectory = "\(directory)/\(dir)"
        
        //let path1 = Bundle.module.url(forResource: "subject", withExtension: "txt", subdirectory: inDirectory)
        
        
        let path1 = Bundle.module.path(forResource: "subject", ofType: "txt", inDirectory: inDirectory)
        print(path1!)
        
        //let path = Path("Templates/\(directory)/\(dir)")
        let path = Path(inDirectory)
        
        
        //let environment = Environment(loader: FileSystemLoader(paths: [path]))
        let environment = Environment(loader: FileSystemLoader(bundle: [Bundle.module]))
                
        let subject = try! environment.renderTemplate(name: "\(inDirectory)/subject.txt", context: context)
        let plainTextBody = try! environment.renderTemplate(name: "\(inDirectory)/plain_text_body.txt", context: context)

        return (subject, plainTextBody, "")
    }
}

extension Theme: Codable {}

extension Theme: Identifiable {
    public var identifier: MessageID {
        return name
    }
}
