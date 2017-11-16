//
//  UserInfoCell.swift
//  Black
//
//  Created by Tjaz Hrovat on 15/11/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import UIKit

class UserInfoCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    
}
