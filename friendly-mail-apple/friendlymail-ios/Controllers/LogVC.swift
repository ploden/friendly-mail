//
//  LogVC.swift
//  friendlymail
//
//  Created by Philip Loden on 7/30/21.
//

import Foundation
import UIKit

class LogVC: UIViewController {
    var logText: String?
    @IBOutlet weak var textView: UITextView? {
        didSet {
            textView?.text = logText
        }
    }
    
    
}
