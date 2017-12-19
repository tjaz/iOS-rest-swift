//
//  TodayViewController.swift
//  Blue
//
//  Created by Tjaz Hrovat on 14/12/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import UIKit
import NotificationCenter
import GithubKit

class TodayViewController: UIViewController, NCWidgetProviding, UIGestureRecognizerDelegate {
    
    struct UserCodable: Codable {
        let login: String
        let blog: String
    }
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var blogTextView: UITextView!
    
    func random(top: Int) -> Int {
        return Int(arc4random_uniform(UInt32(top)))
    }
    
    @objc func onViewTapped() {
        print("ON VIEW TAPPED")
        guard let blackURL = URL(string: "Black://") else {
            return
        }
        self.extensionContext?.open(blackURL, completionHandler: { (opened) in
            if opened {
                print("APP OPENED")
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onViewTapped))
        tapGestureRecognizer.delegate = self
        stackView.addGestureRecognizer(tapGestureRecognizer)
        
        GithubNetworking.getUsers(page: random(top: 10) + 1, perPage: 1, userCallback: { (url) in
            let decoder = JSONDecoder()
            let userData = try Data(contentsOf: url, options: [])
            let userDecoded =  try decoder.decode(UserCodable.self, from: userData)
            
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.duration = 1
            animation.fromValue = NSNumber(value: 0)
            animation.toValue = NSNumber(value: 1)
            DispatchQueue.main.async {
                self.usernameLabel.text = userDecoded.login
                self.blogTextView.text = userDecoded.blog
                self.stackView.layer.add(animation, forKey: "fadein")
            }
            
            
            print(userDecoded.login)
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
