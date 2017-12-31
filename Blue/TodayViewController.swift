//
//  TodayViewController.swift
//  Blue
//
//  Created by Tjaz Hrovat on 26/12/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
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
    @IBOutlet weak var blogTexView: UITextView!
    
    var propertyAnimator: UIViewPropertyAnimator?
    
    @objc func onUsernameLabelTapped() {
        print("ON USER LABEL TAPPED")
        
        guard let blackURL = URL(string: "Black://") else {
            return
        }
        
        self.extensionContext?.open(blackURL, completionHandler: { (isOpening) in
            if isOpening {
                print("SWITCHING TO BLACK")
            }
        })
    }
    
    func random(top: Int) -> Int {
        return Int(arc4random_uniform(UInt32(top)))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector (onUsernameLabelTapped))
        tapGestureRecognizer.delegate = self
        self.usernameLabel.isUserInteractionEnabled = true
        self.usernameLabel.addGestureRecognizer(tapGestureRecognizer)
        
        self.propertyAnimator = UIViewPropertyAnimator(duration: 0.5, curve: UIViewAnimationCurve.linear, animations: {
            self.stackView.layer.opacity = 1
        })
        
        self.stackView.layer.opacity = 0
        
        Rest.getJavaDevelopers(page: random(top: 10) + 1, perPage: 1, userCallback: { (url) in
            print("SHOW USER")
            let decoder = JSONDecoder()
            let userData = try Data(contentsOf: url)
            let userDecoded = try decoder.decode(UserCodable.self, from: userData)
            
            DispatchQueue.main.async {
                self.usernameLabel.text = userDecoded.login
                if let blog = userDecoded.blog {
                    self.blogTexView.text = blog
                    self.self.blogTexView.isHidden = false
                } else {
                    self.self.blogTexView.isHidden = true
                }
            }
            
        }) { (error) in
            if let error = error {
                print(error)
                return
            }
            DispatchQueue.main.async {
                self.propertyAnimator?.startAnimation()
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
