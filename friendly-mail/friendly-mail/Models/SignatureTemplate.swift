//
//  SignatureTemplate.swift
//  friendly-mail
//
//  Created by Philip Loden on 1/11/22.
//

import Foundation

class SignatureTemplate: Template {
    override func plaintTextTemplateURL() -> URL? {
        if let path = Bundle.main.path(forResource: "signature_template", ofType: "txt") {
            return URL(fileURLWithPath: path)
        }
        return nil
    }
    
}
