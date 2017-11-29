//
//  TodayViewController.swift
//  Blue
//
//  Created by Tjaz Hrovat on 25/11/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import UIKit
import NotificationCenter
import NetworkKit

class TodayViewController: UIViewController, NCWidgetProviding {
    
    struct UserCodable: Codable {
        let login: String?
    }
    
    @IBAction func mainAppButton(_ sender: Any) {
        let appURL = URL(string: "Black://")!
        self.extensionContext?.open(appURL, completionHandler: { (success) in
            if success {
                print("main app was successfully opened.")
            }
        })
    }
    
    @IBOutlet weak var developerNameLabel: UILabel!
    
    func random(top: Int) -> Int {
        return Int(arc4random_uniform(UInt32(top)))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        
        Networking.requestJavaDevelopers(page: random(top: 10) + 1, perPage: 1, returnUser: { (item) in
            let decoder = JSONDecoder()
            let userData = try Data(contentsOf: item.url, options: [])
            let userCodable = try decoder.decode(UserCodable.self, from: userData)
            DispatchQueue.main.async {
                self.developerNameLabel.text = userCodable.login
            }
        }) { (error) in
            if error != nil {
                print(error!)
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
