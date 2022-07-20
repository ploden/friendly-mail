//
//  UITabBarController.swift
//  friendly-mail-ios
//
//  Created by Philip Loden on 7/19/22.
//

import Foundation
import UIKit

extension UITabBarController {
    
    func findStatusVC() -> StatusVC? {
        if let vcs = self.viewControllers {
            for vc in vcs {
                if vc is StatusVC {
                    return vc as? StatusVC
                } else {
                    if let nc = vc as? UINavigationController {
                        if nc.topViewController is StatusVC {
                            return nc.topViewController as? StatusVC
                        }
                    }
                }
            }
        }
        return nil
    }
    
    func findFollowingFollowersVC() -> FollowersFollowingVC? {
        if let vcs = self.viewControllers {
            for vc in vcs {
                if vc is FollowersFollowingVC {
                    return vc as? FollowersFollowingVC
                } else {
                    if let nc = vc as? UINavigationController {
                        if nc.topViewController is FollowersFollowingVC {
                            return nc.topViewController as? FollowersFollowingVC
                        }
                    }
                }
            }
        }
        return nil
    }
    
}
