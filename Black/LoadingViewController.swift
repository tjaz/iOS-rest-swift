//
//  LoadingViewController.swift
//  Black
//
//  Created by Tjaz Hrovat on 29/12/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import UIKit

struct UserInfo {
    let avatarData: NSData
    let name: String?
    let company: String?
    let blog: String?
    let location: String?
    let email: String?
    let public_repos: Int
    let followers: Int
}

class LoadingViewController: UIViewController {
    
    struct UserInfoCodable: Codable {
        let name: String?
        let company: String?
        let blog: String?
        let location: String?
        let email: String?
        let public_repos: Int
        let followers: Int
    }
    
    var developer: JavaDeveloper?
    var userInfo: UserInfo?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController!.setNavigationBarHidden(true, animated: false)
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            do {
                let decoder = JSONDecoder()
                let userData = try Data(contentsOf: self.developer!.url!)
                let userDecoded = try decoder.decode(UserInfoCodable.self, from: userData)
                
                self.userInfo = UserInfo(avatarData: self.developer!.avatar!, name: userDecoded.name, company: userDecoded.company, blog: userDecoded.blog, location: userDecoded.location, email: userDecoded.email, public_repos: userDecoded.public_repos, followers: userDecoded.followers)
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "userInfo", sender: nil)
                    self.navigationController!.setNavigationBarHidden(false, animated: false)
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.triggerErrorAlert(error)
                }
            }
        }
    }
    
    func triggerErrorAlert(_ error: Error) {
        print("ERROR")
        print(error)
        let alert = UIAlertController(title: "Error", message: "Error while dispatching data from server: " + error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
        let confirmAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default) { (_) in
            self.navigationController!.popViewController(animated: true)
            self.navigationController!.setNavigationBarHidden(false, animated: false)
        }
        alert.addAction(confirmAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let userInfoController = segue.destination as? UserInfoTableViewController {
            userInfoController.user = self.userInfo
        }
    }
}
