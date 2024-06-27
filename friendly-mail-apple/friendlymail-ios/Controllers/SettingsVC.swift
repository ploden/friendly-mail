//
//  SettingsVC.swift
//  friendlymail
//
//  Created by Philip Loden on 7/26/21.
//

import Foundation
import UIKit
import friendlymail_core

class SettingsVC: UIViewController, HasMailProvider {
    enum Sections: Int {
        case themes = 0
    }
    
    var isLoadingData = false
    var mailProvider: MailProvider!
    
    @IBOutlet weak var tableView: UITableView? {
        didSet {
            tableView?.register(UITableViewCell.self, forCellReuseIdentifier: String(describing: UITableViewCell.self))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AppleSettings.addObserver(forSettings: self)
        navigationItem.title = "Settings"
    }
}

extension SettingsVC: SettingsObserver {
    func settingsDidChange(_ notification: Foundation.Notification) {
    OperationQueue.main.addOperation {
        if ((UIApplication.shared.delegate as? AppDelegate)?.settings) != nil {
            self.tableView?.reloadData()
        }
    }
  }
}

extension SettingsVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let section = Sections(rawValue: indexPath.section) {
            switch section {
            case .themes:
                if
                    let app = (UIApplication.shared.delegate as? AppDelegate),
                    indexPath.row < app.appConfig.themes.count,
                    let settings = (UIApplication.shared.delegate as? AppDelegate)?.settings
                {
                    let theme = app.appConfig.themes[indexPath.row]
                    
                    /*
                    if theme != settings.selectedTheme {
                        _ = settings.new(withSelectedTheme: theme).save(toUserDefaults: .standard)
                    }
                     */
                }
            }
            
        }
    }
}

extension SettingsVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let section = Sections(rawValue: section) {
            switch section {
            case .themes:
                return "Themes"
            }
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let section = Sections(rawValue: section) {
            switch section {
            case .themes:
                return (UIApplication.shared.delegate as? AppDelegate)?.appConfig.themes.count ?? 0
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tvc = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self))
        
        if let section = Sections(rawValue: indexPath.section) {
            switch section {
            case .themes:
                if
                    let app = (UIApplication.shared.delegate as? AppDelegate),
                    indexPath.row < app.appConfig.themes.count
                {
                    let theme = app.appConfig.themes[indexPath.row]
                    tvc?.textLabel?.text = theme.name
                    
                    if let settings = (UIApplication.shared.delegate as? AppDelegate)?.settings {
                        //tvc?.accessoryType = theme == settings.selectedTheme ? .checkmark : .none
                    }
                    
                }
            }
        }
        
        return tvc!
    }
    
}
