//
//  UserTableViewController
//  Black
//
//  Created by Tjaz Hrovat on 18/12/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import UIKit

class UserTableViewController: UITableViewController {
    
    struct UserInformationCodable: Codable {
        let name: String?
        let company: String?
        let blog: String?
        let location: String?
        let email: String?
        let public_repos: Int
        let followers: Int
    }
    
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var companyLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var blogTextField: UITextView!
    @IBOutlet weak var repositoriesLabel: UILabel!
    @IBOutlet weak var followersLabel: UILabel!

    var developer: JavaDeveloper?
    var isDataLoaded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !self.isDataLoaded {
            self.isDataLoaded = true
            self.performSegue(withIdentifier: "loading", sender: nil)
            DispatchQueue.global(qos: .default).async {
                do {
                    let decoder = JSONDecoder()
                    let userData = try Data(contentsOf: self.developer!.url!)
                    let userDecoded = try decoder.decode(UserInformationCodable.self, from: userData)
                    
                    DispatchQueue.main.async {
                        if let avatarData = self.developer!.avatar {
                            if let image = UIImage(data: avatarData as Data) {
                                self.avatarImage.image = image
                            } else {
                                print("ERROR: Can't create user avatar image (data curruption).")
                            }
                        }
                        
                        if userDecoded.name != nil {
                            self.nameLabel.text = userDecoded.name
                        }
                        if  self.locationLabel != nil {
                            self.locationLabel.text = userDecoded.location
                        }
                        if  self.companyLabel != nil {
                            self.companyLabel.text = userDecoded.company
                        }
                        if  self.emailLabel != nil {
                            self.companyLabel.text = userDecoded.email
                        }
                        if  self.blogTextField != nil {
                            self.blogTextField.text = userDecoded.blog
                        }
                        self.repositoriesLabel.text = String(userDecoded.public_repos)
                        self.followersLabel.text = String(userDecoded.followers)
                        if UIDevice.current.userInterfaceIdiom == .pad {
                            self.followersLabel.textAlignment = .right
                        }
                        
                        self.dismiss(animated: true, completion: nil)
                        print("USER DATA LOADED")
                    }
                    
                } catch {
                    DispatchQueue.main.async {
                        print(error)
                        let alert = UIAlertController(title: "Error", message: "Error while dispatching data from server.", preferredStyle: UIAlertControllerStyle.alert)
                        let action = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { (_) in
                            self.navigationController?.popViewController(animated: false)
                        })
                        alert.addAction(action)
                        self.dismiss(animated: false, completion: {
                            self.navigationController!.topViewController!.present(alert, animated: true, completion: nil)
                        })
                        
                    }
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
