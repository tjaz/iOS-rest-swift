//
//  UserInfoTableViewController.swift
//  Black
//
//  Created by Tjaz Hrovat on 30/12/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import UIKit

class UserInfoTableViewController: UITableViewController {

    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var companyLabel: UILabel!
    @IBOutlet weak var blogTextField: UITextView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var repositoriesLabel: UILabel!
    @IBOutlet weak var followersLabel: UILabel!
    
    
    var  user :UserInfo?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let rootVC = navigationController!.viewControllers.first!
        navigationController!.viewControllers = [rootVC, self]
        
        self.avatarImage.image = UIImage(data: user!.avatarData as Data)
        if user!.name != nil {
            self.nameLabel.text = user!.name
        }
        if user!.company != nil {
            self.companyLabel.text = user!.company
        }
        if user!.blog != nil {
            self.blogTextField.text = user!.blog
        }
        if user!.location != nil {
            self.locationLabel.text = user!.location
        }
        if user!.email != nil {
            self.emailLabel.text = user!.email
        }
        self.repositoriesLabel.text = String(user!.public_repos)
        self.followersLabel.text = String(user!.followers)
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.followersLabel.textAlignment = .right
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
