//
//  SignatureTemplate.swift
//  friendly-mail
//
//  Created by Philip Loden on 1/11/22.
//

import Foundation

class SignatureTemplate: Template {
    func populatePlainText() -> String? {
        if let url = plainTextTemplateURL() {
            return populate(with: [], withURL: url)
        }
        return nil
    }
}
