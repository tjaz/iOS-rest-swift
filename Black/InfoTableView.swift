//
//  InfoTableView.swift
//  Black
//
//  Created by Tjaz Hrovat on 28/11/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import UIKit

class InfoTableView: UITableView, UITableViewDataSource {
    
    public var names = [String]()
    public var values = [String]()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.names.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.dequeueReusableCell(withIdentifier: "infoCell") as! InfoTableViewCell
        cell.nameLabel.text = self.names[indexPath.row]
        cell.valueLabel.text = self.values[indexPath.row]
        return cell
    }

    
}
