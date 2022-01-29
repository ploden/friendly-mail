//
//  FollowersFollowingVC.swift
//  friendly-mail
//
//  Created by Philip Loden on 7/22/21.
//

import Foundation
import UIKit

class FollowersFollowingVC: UIViewController {
    @IBOutlet weak var tableView: UITableView? {
        didSet {
            tableView?.register(UITableViewCell.self, forCellReuseIdentifier: String(describing: UITableViewCell.self))
        }
    }
    
    var users: [Address] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Settings.addObserver(forSettings: self)     
    }
    
    @IBAction func addButtonTapped(sender: Any) {
        let ac = UIAlertController(title: "New", message: "Add email address", preferredStyle: .alert)
        ac.addTextField(configurationHandler: nil)
        
        let addAction = UIAlertAction(title: "Add", style: .default) { action in
            if (ac.textFields?.first?.text) != nil {
                if let _ = (UIApplication.shared.delegate as? AppDelegate)?.settings {}
            }
            self.dismiss(animated: true, completion: nil)
            
        }
        ac.addAction(addAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        ac.addAction(cancelAction)
        
        present(ac, animated: true, completion: nil)
    }
    
}

extension FollowersFollowingVC: SettingsObserver {
    func settingsDidChange(_ notification: Foundation.Notification) {
    OperationQueue.main.addOperation {
        if ((UIApplication.shared.delegate as? AppDelegate)?.settings) != nil {
            self.tableView?.reloadData()
        }
    }
  }
}

extension FollowersFollowingVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}
}

extension FollowersFollowingVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tvc = tableView.dequeueReusableCell(withIdentifier: String(describing: MainMenuTVCell.self))
        
        if let _ = tvc as? MainMenuTVCell {}
        
        return tvc!
    }
}
