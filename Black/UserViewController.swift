//
//  UserViewController.swift
//  Black
//
//  Created by Tjaz Hrovat on 18/11/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import UIKit

class UserViewController: UIViewController {
    
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var attributeTable: UserTableView!
    @IBOutlet weak var avatarImage: UIImageView!
    
    var values: [String] = [String]() 
    
    open func setUserInformation(user : DetailedUser) {
        avatarImage.image = user.avatar
        followersLabel.text = "Followers: \(user.followers)"
        if (user.isPhone) {
            followersLabel.textAlignment = NSTextAlignment.left
        } else {
            followersLabel.textAlignment = NSTextAlignment.right
        }
        attributeTable.updateCellContent(values: [user.name, user.type, user.company, user.location, user.email])
    }

}
