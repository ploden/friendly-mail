//
//  StatusVC.swift
//  friendly-mail
//
//  Created by Philip Loden on 1/31/22.
//

import Foundation
import UIKit
import friendly_mail_core

class StatusVC: FMViewController, HasMailProvider {
    var mailProvider: MailProvider!
    var isLoadingData = false
    
    @IBOutlet weak var tableView: UITableView? {
        didSet {
            let cellID = String(describing: StatusTVCell.self)
            tableView?.register(UINib(nibName: cellID, bundle: nil), forCellReuseIdentifier: cellID)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:  #selector(refreshControlValueChanged), for: .valueChanged)
        tableView?.refreshControl = refreshControl
        
        if let settings = (UIApplication.shared.delegate as? AppDelegate)?.settings {
            loadData()
            tableView?.refreshControl?.beginRefreshing()
        }
        
    }
    
    @objc func refreshControlValueChanged() {
        if
            let refreshControl = tableView?.refreshControl,
            refreshControl.isRefreshing,
            let mailProvider = mailProvider,
            mailProvider.settings.isValid
        {
            loadData()
        } else {
            tableView?.refreshControl?.endRefreshing()
        }
    }
    
    func loadData() {
        guard
            let mailProvider = mailProvider,
            let settings = (UIApplication.shared.delegate as? AppDelegate)?.settings,
            isLoadingData == false
        else {
            return
        }
        
        isLoadingData = true
        
        let config = (UIApplication.shared.delegate as? AppDelegate)!.appConfig
        let logger = (UIApplication.shared.delegate as? AppDelegate)!.logger
        
        MailController.getAndProcessAndSendMail(config: config, sender: mailProvider, receiver: mailProvider, messages: mailProvider.messages, logger: logger) { error, updatedMessages in
            OperationQueue.main.addOperation {
                self.mailProvider = mailProvider.new(mergingMessageStores: updatedMessages, postNotification: true)
                NotificationCenter.default.post(name: Foundation.Notification.Name.mailProviderDidChange, object: self.mailProvider)
                self.tableView?.refreshControl?.endRefreshing()
                
                let friendlyMail = updatedMessages.allMessages.filter { message in
                    message.isFriendlyMailMessage()
                }
                
                if let tvc = self.tableView?.visibleCells.first as? StatusTVCell {
                    tvc.friendlyMailCountLabel?.text = "\(friendlyMail.count)"
                    let followersFollowing = MailController.followersFollowing(forAddress: settings.user, messages: mailProvider.messages)
                    tvc.followersCountLabel?.text = "\(followersFollowing.followers.count)"
                    tvc.followingCountLabel?.text = "\(followersFollowing.following.count)"
                }
                
                if let error = error {
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    let action = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(action)
                    self.present(alert, animated: true, completion: nil)
                }
                
                self.isLoadingData = false
            }
        }
    }
    
}

extension StatusVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}
}

extension StatusVC: SettingsObserver {
    func settingsDidChange(_ notification: Foundation.Notification) {
        OperationQueue.main.addOperation {
            if let loaded = AppleSettings(fromUserDefaults: .standard) {
                self.mailProvider = self.mailProvider?.new(withSettings: loaded, postNotification: false)
            }
        }
    }
}

extension StatusVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tvc = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTVCell.self))
        
        if (tvc as? StatusTVCell) != nil {}
        
        return tvc!
    }
}
