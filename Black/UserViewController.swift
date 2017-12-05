//
//  UserViewController.swift
//  Black
//
//  Created by Tjaz Hrovat on 04/12/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import UIKit

class UserViewController: UIViewController {

    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var informationTable: UITableView!
    @IBOutlet weak var followersLabel: UILabel!
    
    var attributes = [String]()
    var values = [Any?]()
    var isDataLoaded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !self.isDataLoaded {
            self.performSegue(withIdentifier: "loading", sender: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension UserViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.attributes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "infoCell")! as! UserViewCell
        let attribute = attributes[indexPath.row]
        cell.attributeLabel.text = attribute + ": "
        
        let value = values[indexPath.row]
        if let text = value as? String {
            cell.dataTextField.dataDetectorTypes = .address
            cell.dataTextField.text = text
        } else if let value = value as? Int {
            cell.dataTextField.text = String(value)
        } else if let url = value as? URL {
            cell.dataTextField.dataDetectorTypes = .link
            cell.dataTextField.text = url.absoluteString
        }
        
        return cell
    }
    
    
}
