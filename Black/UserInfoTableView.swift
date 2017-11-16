//
//  UserInfoTableView.swift
//  Black
//
//  Created by Tjaz Hrovat on 16/11/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import UIKit

class UserInfoTableView: UITableView, UITableViewDataSource {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    var cellTopic: [String] = [String]()
    var cellInfo: [String] = [String]()
    
    func updateTableData(cellData :[String]) {
        cellTopic.append( "Name:" )
        cellTopic.append( "Type:" )
        cellTopic.append( "Company:" )
        cellTopic.append( "Location:" )
        cellTopic.append( "Email:" )
        
        cellInfo = cellData
        self.reloadData()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellInfo.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //let cell = tableView.dequeueReusableCell(withIdentifier: "userInfoCell", for: indexPath) as! UserInfoCell
        let cell = Bundle.main.loadNibNamed("UserInfoCell", owner: self, options: nil)?.first as! UserInfoCell
        
        cell.titleLabel.text = cellTopic[indexPath.row]
        cell.infoLabel.text = cellInfo[indexPath.row]
        
        return cell
    }
    
    //    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    //        return 80.0
    //    }
}
