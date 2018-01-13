//
//  InfoLoadingViewController.swift
//  Black
//
//  Created by Tjaz Hrovat on 12/01/2018.
//  Copyright © 2018 Tjaz Hrovat. All rights reserved.
//

import UIKit

public struct DeveloperInfo {
    let avatarData: NSData?
    let name: String?
    let company: String?
    let blog: String?
    let location: String?
    let email: String?
    let public_repos: Int
    let followers: Int
}

class InfoLoadingViewController: UIViewController {
    
    struct UserInfoCodable: Codable {
        let name: String?
        let company: String?
        let blog: String?
        let location: String?
        let email: String?
        let public_repos: Int
        let followers: Int
    }
    
    var javaDeveloper: JavaDeveloper!
    var developerInfo: DeveloperInfo?
    
    enum TestError: Error {
        case responseError(reason: String)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController!.setNavigationBarHidden(true, animated: false)

        DispatchQueue.global(qos: .default).async {
            do {
                //throw TestError.responseError(reason: "TEST")
                let decoder = JSONDecoder()
                let userData = try Data(contentsOf: self.javaDeveloper.url!)
                let userDecoded = try decoder.decode(UserInfoCodable.self, from: userData)
                
                self.developerInfo = DeveloperInfo(avatarData: self.javaDeveloper.avatar, name: userDecoded.name, company: userDecoded.company, blog: userDecoded.blog, location: userDecoded.location, email: userDecoded.email, public_repos: userDecoded.public_repos, followers: userDecoded.followers)
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "info", sender: self)
                }
                
            } catch {
                print(error)
                self.triggerErrorAlert(error: error)
            }
        }
    }
    
    func triggerErrorAlert(error: Error) {
        print("ERROR")
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
        let confirmAction = UIAlertAction(title: "Continue", style: UIAlertActionStyle.default, handler: { (_) in
            //self.dismiss(animated: true, completion: nil)
            self.navigationController!.popViewController(animated: true)
            self.navigationController!.setNavigationBarHidden(false, animated: false)
        })
        alert.addAction(confirmAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let developerInfoController = segue.destination as? DeveloperInfoTableViewController {
            developerInfoController.developer = self.developerInfo
        }
    }
}
