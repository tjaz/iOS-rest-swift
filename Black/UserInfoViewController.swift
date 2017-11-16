//
//  UserInfoViewController.swift
//  Black
//
//  Created by Tjaz Hrovat on 14/11/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import UIKit

class UserInfoViewController: UIViewController {
    
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var mainTable: UserInfoTableView!
    @IBOutlet weak var mainImageView: UIImageView!
    
    var cellData: [String] = [String]()
       
    open func updateCellInformation(userInfo: CollectedUserInfo)
    {
        cellData.append( userInfo.name )
        cellData.append( userInfo.type )
        cellData.append( userInfo.company )
        cellData.append( userInfo.location )        
        cellData.append( userInfo.email )
        
        self.mainImageView.image = userInfo.avatar
        
        self.mainTable.updateTableData(cellData: cellData)
        
        if userInfo.isPhone {
            self.followersLabel.textAlignment = NSTextAlignment.left
        } else {
            self.followersLabel.textAlignment = NSTextAlignment.right
        }
        self.followersLabel.text = "Following: \(userInfo.following)"
        
    }
    
}
