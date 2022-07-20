//
//  Template.swift
//  friendly-mail
//
//  Created by Philip Loden on 7/29/21.
//

import Foundation

public class Template {
    var htmlTemplateFilename: String?
    var partialHTMLTemplateFilename: String?

    var plainTextTemplateFilename: String?
    var subjectTemplateFilename: String?
    
    let theme: Theme
    
    public init(theme: Theme) {
        self.theme = theme
    }
    
    lazy var defaultResourceName: String = {
        return String(describing: self).snakeCasedTypeName()
    }()
    
    lazy var headCSS: String? = {
        if let path = Bundle.module.path(forResource: "head", ofType: "css", inDirectory: "\(theme.directory)/html") {
            let url = URL(fileURLWithPath: path)
            return try? String(contentsOf: url)
        }
        return nil
    }()
    
    lazy var footer: String? = {
        if let path = Bundle.module.path(forResource: "footer", ofType: "html", inDirectory: "\(theme.directory)/html") {
            let url = URL(fileURLWithPath: path)
            return try? String(contentsOf: url)
        }
        return nil
    }()

    lazy var header: String? = {
        if let path = Bundle.module.path(forResource: "header", ofType: "html", inDirectory: "\(theme.directory)/html") {
            let url = URL(fileURLWithPath: path)
            return try? String(contentsOf: url)
        }
        return nil
    }()
    
    func plainTextTemplateURL() -> URL? {
        let resource = plainTextTemplateFilename ?? "\(defaultResourceName)"
        let dir = "\(theme.directory)/txt"
        if let path = Bundle.module.path(forResource: resource, ofType: "txt", inDirectory: dir) {
            return URL(fileURLWithPath: path)
        }
        return nil
    }
    
    func subjectTemplateURL() -> URL? {
        let resource = subjectTemplateFilename ?? "\(defaultResourceName.replacingOccurrences(of: "_template", with: "_subject_template"))"
        let dir = "\(theme.directory)/txt"
        if let path = Bundle.module.path(forResource: resource, ofType: "txt", inDirectory: dir) {
            return URL(fileURLWithPath: path)
        }
        return nil
    }

    func baseHTMLTemplateURL() -> URL? {
        let filename = "base_template"
        let path = Bundle.module.path(forResource: filename, ofType: "html", inDirectory: "\(theme.directory)/html")
        return URL(fileURLWithPath: path!)
    }
    
    func htmlTemplateURL() -> URL? {
        let filename = htmlTemplateFilename ?? "\(defaultResourceName)"
        let path = Bundle.module.path(forResource: filename, ofType: "html", inDirectory: "\(theme.directory)/html")
        return URL(fileURLWithPath: path!)
    }
    
    func partialHTMLTemplateURL() -> URL? {
        let resource = partialHTMLTemplateFilename ?? "\(defaultResourceName.replacingOccurrences(of: "_template", with: "_partial"))"
        let dir = "\(theme.directory)/html"
        if let path = Bundle.module.path(forResource: resource, ofType: "html", inDirectory: dir) {
            return URL(fileURLWithPath: path)
        }
        return nil
    }
    
    func populate(with: Any, withURL url: URL) -> String? {
        if let templateString = try? String(contentsOf: url, encoding: .utf8) {
            return data(with: with).reduce(templateString) {
                let format = "<!-- ${\($1.key)} -->"
                
                if let dateValue = $1.value as? Date {
                    return $0.replacingOccurrences(of: format, with: displayDateFormatter.string(from: dateValue))
                } else if let stringValue = $1.value as? String {
                    return $0.replacingOccurrences(of: format, with: stringValue)
                } else {
                    return $0.replacingOccurrences(of: format, with: "")
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
