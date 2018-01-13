//
//  TodayViewController.swift
//  Blue
//
//  Created by Tjaz Hrovat on 05/01/2018.
//  Copyright © 2018 Tjaz Hrovat. All rights reserved.
//

import UIKit
import NotificationCenter
import GithubConnectKit

class TodayViewController: UIViewController, NCWidgetProviding, UIGestureRecognizerDelegate {
    struct UserCodable: Codable {
        let login: String
        let blog: String?
    }
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var blogTextField: UITextView!
    
    @objc func onStackViewTapped() {
        print("STACK VIEW TAPPED")
        
        guard let blackURL = URL(string: "Black://") else {
            print("Unable to parse Main application URL")
            return
        }
        self.extensionContext!.open(blackURL) { (isOpened) in
            if isOpened {
                print("BLACK HAS OPENED")
            }
        }
    }
    
    func random(top: Int) -> Int {
        return Int(arc4random_uniform(UInt32(top)))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onStackViewTapped))
        tapGestureRecognizer.delegate = self
        self.stackView.addGestureRecognizer(tapGestureRecognizer)
        
        Rest.getJavaDevelopers(page: random(top: 10) + 1, perPage: 1, userCallback: { (userURL) in
            print("USER RETRIEVED")
            let decoder = JSONDecoder()
            let userData = try Data(contentsOf: userURL)
            let userDecoded = try decoder.decode(UserCodable.self, from: userData)
            
            DispatchQueue.main.async {
                self.stackView.isHidden = false
                self.usernameLabel.text = userDecoded.login
                self.blogTextField.text = userDecoded.blog
            }
            
        }) { (error) in
            if let error = error {
                print(error)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
}
