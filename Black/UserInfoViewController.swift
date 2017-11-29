//
//  UserInfoViewController.swift
//  Black
//
//  Created by Tjaz Hrovat on 27/11/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import UIKit

public struct UserInfoData {
    let names: [String]
    let values: [String]
    let avatar: UIImage
    let followers: String
    let iPhone: Bool
}

class UserInfoViewController: UIViewController {

    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var tableView: InfoTableView!
    @IBOutlet weak var followersLabel: UILabel!
    
    var userData: UserInfoData? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.avatarImage.image = userData?.avatar
        self.followersLabel.text = "Followers: " + userData!.followers
        if !userData!.iPhone {
            self.followersLabel.textAlignment = .right
        }
        tableView.names = userData!.names
        tableView.values = userData!.values        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
  
    
}
