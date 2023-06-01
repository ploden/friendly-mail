//
//  FollowersFollowingVC.swift
//  friendlymail
//
//  Created by Philip Loden on 7/22/21.
//

import Foundation
import UIKit
import friendlymail_core

extension RawRepresentable {
  init?(optionalValue: RawValue?) {
    guard let value = optionalValue else { return nil }
    self.init(rawValue: value)
  }
}

class FollowersFollowingVC: UIViewController, HasMailProvider {
    var isLoadingData = false
    var mailProvider: MailProvider!

    @IBOutlet weak var segmentedControl: UISegmentedControl? {
        didSet {
            self.navigationItem.titleView = segmentedControl
        }
    }
    @IBOutlet weak var tableView: UITableView? {
        didSet {
            tableView?.register(UINib(nibName: String(describing: MainMenuTVCell.self), bundle: nil), forCellReuseIdentifier: String(describing: MainMenuTVCell.self))
        }
    }

    var followers: [EmailAddress] = []
    var following: [EmailAddress] = []
    
    enum Segment: Int {
        case followers = 0
        case following = 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.titleView = segmentedControl

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:  #selector(refreshControlValueChanged), for: .valueChanged)
        tableView?.refreshControl = refreshControl
        
        loadData()
        AppleSettings.addObserver(forSettings: self)
        MailProvider.addObserver(forSettings: self)
    }
    
    @objc func refreshControlValueChanged() {
        if
            let refreshControl = tableView?.refreshControl,
            refreshControl.isRefreshing,
            mailProvider.settings.isValid
        {
            loadData()
        } else {
            tableView?.refreshControl?.endRefreshing()
        }
    }
    
    func loadData() {
        guard
            let settings = (UIApplication.shared.delegate as? AppDelegate)?.settings, isLoadingData == false
        else {
            return
        }
        
        /*
        let followersFollowing = MailController.followersFollowing(forAddress: settings.user, messages: mailProvider.messages)
        followers = followersFollowing.followers
        following = followersFollowing.following
         */
        tableView?.reloadData()
        self.tableView?.refreshControl?.endRefreshing()
    }
    
    @IBAction func segmentedControlValueChanged() {
        tableView?.reloadData()
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
    
    private func usersToShow() -> [EmailAddress] {
        if let segment = Segment(optionalValue: segmentedControl?.selectedSegmentIndex) {
            switch segment {
            case .followers:
                return followers
            case .following:
                return following
            }
        }
        return []
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
        let users = usersToShow()
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tvc = tableView.dequeueReusableCell(withIdentifier: String(describing: MainMenuTVCell.self))
        
        if let tvc = tvc as? MainMenuTVCell {
            let user = usersToShow()[indexPath.row]
            tvc.label?.text = user.displayName
        }
        
        return tvc!
    }
}

extension FollowersFollowingVC: MailProviderObserver {
    @objc func mailProviderDidChange(_ notification: Foundation.Notification) {
        if let mailProvider = notification.object as? MailProvider {
            OperationQueue.main.addOperation {
                self.mailProvider = mailProvider
                self.loadData()
            }
        }
    }
}
