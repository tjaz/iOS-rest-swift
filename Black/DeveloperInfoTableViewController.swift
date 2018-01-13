//
//  DeveloperInfoTableViewController.swift
//  Black
//
//  Created by Tjaz Hrovat on 12/01/2018.
//  Copyright © 2018 Tjaz Hrovat. All rights reserved.
//

import UIKit

class DeveloperInfoTableViewController: UITableViewController {
    
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var companyLabel: UILabel!
    @IBOutlet weak var blogTextView: UITextView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var repositoriesLabel: UILabel!
    @IBOutlet weak var followersLabel: UILabel!
    
    var developer: DeveloperInfo!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController!.setNavigationBarHidden(false, animated: false)
        let rootVC = navigationController!.viewControllers.first!
        navigationController!.viewControllers = [rootVC, self]
        
        
        if let avatarData = self.developer.avatarData {
            self.avatarImage.image = UIImage(data: avatarData as Data)
        }
        if nil != self.developer.name {
            self.nameLabel.text = self.developer.name
        }
        if nil != self.developer.company {
            self.companyLabel.text = self.developer.company
        }
        if nil != self.developer.blog {
            self.blogTextView.text = self.developer.blog
        }
        if nil != self.developer.name {
            self.locationLabel.text = self.developer.location
        }
        if nil != self.developer.email {
            self.emailLabel.text = self.developer.email
        }
        
        self.repositoriesLabel.text = String(self.developer.public_repos)
        
        self.followersLabel.text = String(self.developer.followers)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.followersLabel.textAlignment = .right
        }
        
    }
}
