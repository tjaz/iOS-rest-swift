//
//  TableView.swift
//  iosTest
//
//  Created by Tjaz Hrovat on 07/11/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import UIKit

class TableView: UITableView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    let cellHeight = 100.0
    
    var items: [RowItem] = [RowItem]()
    
    var isPopulateLocked: Bool = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
}

extension TableView: UITableViewDelegate, UITableViewDataSource, TableDelegate
{
    
    func populate(_ tableView: UITableView, items: [RowItem]) {
        if tableView == self
        {
            self.items += items
            //self.contentOffset.y = 0
            //self.reloadData()
            //self.endUpdates()
            self.isPopulateLocked = false
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = Bundle.main.loadNibNamed("TableViewCell", owner: self, options: nil)?.first as! TableViewCell
        
        if indexPath.row < items.count
        {
            
            cell.mainImageView.image = items[indexPath.row].avatar_img
            
            cell.mainLabelView.text = items[indexPath.row].login
            cell.createdLabel.text = "\nRegistered: " + items[indexPath.row].created_at
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return items.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(cellHeight)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (self.isPopulateLocked) {
            return
        }
        
        if(self.contentOffset.y<0){
            //it means table view is pulled down like refresh
            return;
        }

        else if(self.contentOffset.y >= (self.contentSize.height - self.bounds.size.height)) {
            
//            print("bottom!");
            
            let appDelegate  = UIApplication.shared.delegate as! AppDelegate
            let viewController = appDelegate.window!.rootViewController as! ViewController
            viewController.requestPages()
            self.isPopulateLocked = true
        }
    }
    }
