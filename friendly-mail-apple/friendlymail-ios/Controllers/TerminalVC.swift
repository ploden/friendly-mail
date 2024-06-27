//
//  TerminalVC.swift
//  friendlymail-ios
//
//  Created by Philip Loden on 6/26/24.
//

import Foundation
import UIKit
import friendlymail_core

class TerminalVC: UIViewController {
    var mailProvider: MailProvider!
    var isLoadingData = false

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        loadData()
    }

    func loadData() {
        guard
            let mailProvider = mailProvider,
            mailProvider.settings.isValid,
            isLoadingData == false
        else {
            return
        }

        isLoadingData = true

        let config = (UIApplication.shared.delegate as? AppDelegate)!.appConfig
        let logger = (UIApplication.shared.delegate as? AppDelegate)!.logger
        let storageProvider = (UIApplication.shared.delegate as? AppDelegate)!.storageProvider

        MailController.getAndProcessAndSendMail(config: config, sender: mailProvider, receiver: mailProvider, messages: mailProvider.messages, storageProvider: storageProvider, logger: logger) { error, updatedMessages in
            OperationQueue.main.addOperation {
                self.mailProvider = mailProvider.new(mergingMessageStore: updatedMessages, postNotification: true)
                NotificationCenter.default.post(name: Foundation.Notification.Name.mailProviderDidChange, object: self.mailProvider)

                if let error = error {
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    let action = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(action)
                    self.present(alert, animated: true, completion: nil)
                }

                self.isLoadingData = false

                DispatchQueue.main.asyncAfter(deadline: .now() + Double(UInt.random(in: 1..<10))) { [weak self] in
                    self?.loadData()
                }
            }
        }
    }

}
