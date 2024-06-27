//
//  StatusTVCell.swift
//  friendlymail
//
//  Created by Philip Loden on 2/3/22.
//

import Foundation
import UIKit

class StatusTVCell: UITableViewCell {
    @IBOutlet weak var friendlyMailCountLabel: UILabel? {
        didSet {
            configureFont(label: friendlyMailCountLabel)
        }
    }
    @IBOutlet weak var followersCountLabel: UILabel? {
        didSet {
            configureFont(label: followersCountLabel)
        }
    }
    @IBOutlet weak var followingCountLabel: UILabel? {
        didSet {
            configureFont(label: followingCountLabel)
        }
    }
    
    func configureFont(label: UILabel?) {
        if let label = label {
            label.font = UIFont(name: "UbuntuMono-Regular", size: label.font.pointSize)
        }
    }
}
