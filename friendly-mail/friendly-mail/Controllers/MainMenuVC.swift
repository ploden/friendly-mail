//
//  MainMenuVC.swift
//  friendly-mail
//
//  Created by Philip Loden on 7/17/21.
//

import UIKit
import Logging

class MainMenuVC: FMViewController {
    var mailProvider: MailProvider!
    var notifications = [Any]()
    
    @IBOutlet weak var tableView: UITableView? {
        didSet {
            let cellID = String(describing: MainMenuTVCell.self)
            tableView?.register(UINib(nibName: cellID, bundle: nil), forCellReuseIdentifier: cellID)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:  #selector(refreshControlValueChanged), for: .valueChanged)
        tableView?.refreshControl = refreshControl
        
        if let font = UIFont(name: "American Typewriter", size: 12.0) {
            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: font]
        }
        
        navigationItem.title = "friendly-mail"
        
        if let settings = (UIApplication.shared.delegate as? AppDelegate)?.settings {
            notifications = MailController.newsFeedNotifications(settings: settings, messages: self.mailProvider.messages)
            tableView?.reloadData()
            loadData()
            tableView?.refreshControl?.beginRefreshing()
        }
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
        guard let settings = (UIApplication.shared.delegate as? AppDelegate)?.settings else {
            return
        }
        
        MailController.getAndProcessAndSendMail(sender: self.mailProvider, receiver: self.mailProvider, settings: settings, messages: self.mailProvider.messages) { error, updatedMessages in
            OperationQueue.main.addOperation {
                self.mailProvider = self.mailProvider.new(mergingMessageStores: updatedMessages)
                self.tableView?.refreshControl?.endRefreshing()
                
                self.notifications = MailController.newsFeedNotifications(settings: settings, messages: self.mailProvider.messages)
                self.tableView?.reloadData()
                
                if let error = error {
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    let action = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(action)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
}

extension MainMenuVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tvc = tableView.dequeueReusableCell(withIdentifier: String(describing: MainMenuTVCell.self))
        
        if let tvc = tvc as? MainMenuTVCell {
            let newLikeTemplate = NewLikeNotificationTemplate()
            let newCommentTemplate = NewCommentNotificationTemplate()
            
            let notification = notifications[indexPath.row]
            
            if let notification = notification as? NewLikeNotificationWithMessages {
                let text = newLikeTemplate.populatePlainText(notification: notification.notification, createLikeMessage: notification.createLikeMessage, createPostMessage: notification.createPostMessage)
                tvc.label?.text = text
            } else if let notification = notification as? NewCommentNotificationWithMessages {
                let text = newCommentTemplate.populatePlainText(with: notification)
                tvc.label?.text = text
            }
        }
        
        return tvc!
    }
}

extension MainMenuVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}
}

extension MainMenuVC: SettingsObserver {
    func settingsDidChange(_ notification: Foundation.Notification) {
        OperationQueue.main.addOperation {
            if let loaded = Settings(fromUserDefaults: .standard) {
                self.mailProvider = self.mailProvider.new(withSettings: loaded)
            }
        }
    }
}
