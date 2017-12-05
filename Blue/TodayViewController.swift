//
//  TodayViewController.swift
//  Blue
//
//  Created by Tjaz Hrovat on 02/12/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import UIKit
import NotificationCenter
import NetworkingKit

class TodayViewController: UIViewController, NCWidgetProviding {
    
    struct UserCodable: Codable {
        let login: String?
    }
    
    func random(_ top: Int) -> Int {
        return Int(arc4random_uniform(UInt32(top)))
    }
    
    @IBOutlet weak var userLabel: UILabel!
    @IBAction func onButtonTapped(_ sender: Any) {
        guard let blackURL = URL(string: "Black://") else {
            return
        }
        self.extensionContext?.open(blackURL, completionHandler: { (opened) in
            if opened {
                print("BLACK OPENED")
            }
        })
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        
        GithubConnect.getJavaDevelopers(page: random(10) + 1, perPage: 1, userCallback: { (url) in
            let decoder = JSONDecoder()
            let userData = try Data(contentsOf: url)
            let userDecoded = try decoder.decode(UserCodable.self, from: userData)
            if let username = userDecoded.login {
                DispatchQueue.main.async {
                    self.userLabel.text = username
                }
            }
            
        }) { (error) in
            if let error = error {
                print(error)
                return
            }
            print("COMPLETE")
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
