//
//  UserTableView.swift
//  Black
//
//  Created by Tjaz Hrovat on 18/11/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import UIKit

class UserTableView: UITableView, UITableViewDataSource {
   
    let cellAttributes: [String] = ["Name:", "Type:", "Company:", "Location:", "Email:"]
    var cellValues: [String] = [String]()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.dataSource = self
    }
    
    open func updateCellContent(values :[String]) {
        self.cellValues = values
        self.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellAttributes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("UserTableViewCell", owner: self, options: nil)?.first as! UserTableViewCell
        
        cell.attributeLabel.text = cellAttributes[indexPath.row]
        cell.valueLabel.text = cellValues[indexPath.row]
        
        return cell
    }

}
