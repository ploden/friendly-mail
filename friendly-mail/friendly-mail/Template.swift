//
//  Template.swift
//  friendly-mail
//
//  Created by Philip Loden on 7/29/21.
//

import Foundation

class Template {
    func plaintTextTemplateURL() -> URL? {
        return nil
    }
    func htmlTemplateURL() -> URL? {
        return nil
    }
    func subjectTemplateURL() -> URL? {
        return nil
    }
    
    func populatePlainText(with: Any) -> String? {
        if let url = plaintTextTemplateURL() {
            let str = populate(with: with, withURL: url)
            return str
        }
        return nil
    }
    
    func populateHTML(with: Any) -> String? {
        return nil
    }
    
    func populateSubject(with: Any) -> String? {
        if let url = subjectTemplateURL() {
            let str = populate(with: with, withURL: url)
            return str
        }
        return nil
    }
    
    func populate(with: Any, withURL url: URL) -> String? {
        if let templateString = try? String(contentsOf: url, encoding: .utf8) {
            return data(with: with).reduce(templateString) {
                if let dateValue = $1.value as? Date {
                    return $0.replacingOccurrences(of: "${\($1.key)}", with: displayDateFormatter.string(from: dateValue))
                } else if let stringValue = $1.value as? String {
                    return $0.replacingOccurrences(of: "${\($1.key)}", with: stringValue)
                } else {
                    return $0.replacingOccurrences(of: "${\($1.key)}", with: "")
                }
            }
        }
        
        return nil
    }
    
    func data(with: Any) -> [String:Any] {
        return [:]
    }

    let displayDateFormatter : DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMMM d' at 'h:mm a"
        formatter.calendar = Calendar(identifier: .gregorian)
        
        return formatter
    }()
    
    let dateFormatter : DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        formatter.calendar = Calendar(identifier: .gregorian)
        
        return formatter
    }()
}
