//
//  TodayViewController.swift
//  Blue
//
//  Created by Tjaz Hrovat on 23/11/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import UIKit
import NotificationCenter
import NetworkKit


class TodayViewController: UIViewController, NCWidgetProviding {
    
    enum BackendError: Error {
        case urlError(reason:String)
        case noResponse(reason:String)
    }
    
    struct User: Codable {
        let name: String
    }
    
    func random(max maxNumber: Int) -> Int {
        return Int(arc4random_uniform(UInt32(maxNumber)))
    }
    
    @IBOutlet weak var usernameLabel: UILabel!
    
    let items = 10
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        
        let randomPerson = random(max: self.items) + 1
        
        Networking.requestUserItems(page: randomPerson, perPage: 1) { (urlItems, error) in
            
            do {
                if let error = error {
                    throw error
                }
                
                let decoder = JSONDecoder()
                
                for urlItem in urlItems! {
                    guard let userURL = URL(string: urlItem.url) else {
                        throw BackendError.urlError(reason: "unable to parse user url.")
                    }
                    
                    let userData = try Data(contentsOf: userURL)
                    let userDecodable = try decoder.decode(User.self, from: userData)

                    print(userDecodable.name)
                    
                    self.usernameLabel.text = userDecodable.name
                }
                
            } catch{
                print( error )
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
