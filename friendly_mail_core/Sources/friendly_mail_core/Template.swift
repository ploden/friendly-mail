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
    
    var friendlyMailData: String?

    let theme: Theme
    
    public init(theme: Theme) {
        self.theme = theme
    }
    
    lazy var defaultResourceName: String = {
        return String(describing: self).snakeCasedTypeName()
    }()
    
    lazy var headCSS_0: String? = {
        if let path = Bundle.module.path(forResource: "head_css_0", ofType: "html", inDirectory: "\(theme.directory)/html") {
            let url = URL(fileURLWithPath: path)
            return try? String(contentsOf: url)
        }
        return nil
    }()
    
    lazy var headCSS_1: String? = {
        if let path = Bundle.module.path(forResource: "head_css_1", ofType: "html", inDirectory: "\(theme.directory)/html") {
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
    
    func populateBaseHTML() -> String? {
        if let url = baseHTMLTemplateURL() {
            var data = [String:Any]()
            if let headCSS_0 = headCSS_0 {
                data["head_css_0"] = headCSS_0
            }
            if let headCSS_1 = headCSS_1 {
                data["head_css_1"] = headCSS_1
            }
            if let footer = footer {
                data["footer"] = footer
            }
            if let header = header {
                data["header"] = header
            }
            if let friendlyMailData = friendlyMailData {
                data["friendly-mail_data"] = friendlyMailData
            }
            let html = populate(url: url, with: data)
            return html
        }
        return nil
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

    func populate(string: String, with: [String:Any]) -> String? {
        return with.reduce(string) {
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
    
    func populate(string: String, with: Any) -> String? {
        let keysValues = data(with: with)
        return populate(string: string, with: keysValues)
    }
    
    func populate(url: URL, with: [String:Any]) -> String? {
        if let templateString = try? String(contentsOf: url, encoding: .utf8) {
            return populate(string: templateString, with: with)
        }
        
        return nil
    }
    
    func populate(url: URL, with: Any) -> String? {
        if let templateString = try? String(contentsOf: url, encoding: .utf8) {
            return populate(string: templateString, with: with)
        }
        
        return nil
    }
    
    func data(with: Any) -> [String:Any] {
        let result = with as? [String:Any] ?? [:]
        return result
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

extension Template {
    enum PlainText: String {
        case signature = "friendly-mail, an open-source, email-based, alternative social network"
    }
}
