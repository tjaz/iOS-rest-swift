//
//  RootPageViewController.swift
//  Black
//
//  Created by Tjaz Hrovat on 05/01/2018.
//  Copyright © 2018 Tjaz Hrovat. All rights reserved.
//

import UIKit
import GithubConnectKit
import SQLite
import CoreData

enum DataStatus {
    case new
    case update
    case reload
}

class RootPageViewController: UIPageViewController, UIPageViewControllerDataSource {
    
    var database: Connection!
    var page: Int {
        return self.developers.count + 1
    }
    let perPage: Int = 10
    var developers = [JavaDeveloper]()
    var viewControllerList = [UIViewController]()
    var dataStatus: DataStatus = .reload
    let updateInterval = 5
//    var isPageLoading: Bool {
//        if let childVC = self.viewControllerList.last as! MainTableViewController? {
//            return childVC.isPageLoaded
//        }
//        return false
//    }
    
    var isLoadingPage = false
    
    let userTable = Table("users")
    let idExpr = Expression<Int>("id")
    let pageIdExpr = Expression<Int>("pageId")
    let usernameExpr = Expression<String>("username")
    
    override func viewDidLoad() {
        self.dataSource = self
        do {
            let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileUrl = documentDirectory.appendingPathComponent("users").appendingPathExtension("sqlite3")
            let database = try Connection(fileUrl.path)
            self.database = database
            
            let fetchDataRecord: NSFetchRequest<DataRecord> = DataRecord.fetchRequest()
            let dataRecords = try PersistentStorage.context.fetch(fetchDataRecord)
            if dataRecords.count == 0 {
                let dataRecord = DataRecord(context: PersistentStorage.context)
                dataRecord.created = NSDate(timeIntervalSince1970: NSTimeIntervalSince1970)
                PersistentStorage.saveContext()
                self.dataStatus = .reload
                
                let createTable = self.userTable.create { (table) in
                    table.column(self.idExpr, primaryKey: true)
                    table.column(self.pageIdExpr)
                    table.column(self.usernameExpr)
                }
                
                try self.database.run(createTable)
                
            } else {
                
                try updateDataStatus()
                
                let fetchJavaDevelopers: NSFetchRequest<JavaDeveloper> = JavaDeveloper.fetchRequest()
                self.developers = try PersistentStorage.context.fetch(fetchJavaDevelopers)
                
                self.prepareNextPage()
                self.setViewControllers(self.viewControllerList, direction: .forward, animated: true, completion: nil)
            }
            

        } catch {
            print(error)
            return
        }
    }
    
    func updateDataStatus()throws -> Void {
        let fetchDataRecord: NSFetchRequest<DataRecord> = DataRecord.fetchRequest()
        let dataRecords = try PersistentStorage.context.fetch(fetchDataRecord)
        
        let interval:Double = Date().timeIntervalSince(dataRecords[0].created as Date!)
        let elapsedTimeInMinutes = Int64(interval) / 60
        
        if elapsedTimeInMinutes > self.updateInterval {
            self.dataStatus = .update
            print("DATA STATUS UPDATE \(elapsedTimeInMinutes)")
        } else {
            self.dataStatus = .new
            print("DATA STATUS NEW \(elapsedTimeInMinutes)")
        }
    }
    
    func reloadData()throws -> Void {
        self.isLoadingPage = true
        self.dataStatus = .reload
        
        try self.database.execute("DELETE FROM users")
        
        let fetchJavaDevelopers: NSFetchRequest<JavaDeveloper> = JavaDeveloper.fetchRequest()
        let javaDevelopers = try PersistentStorage.context.fetch(fetchJavaDevelopers)
        for developer in javaDevelopers {
            PersistentStorage.context.delete(developer)
        }
        
        self.developers = []
        self.viewControllerList = []
        self.prepareNextPage()
        self.setViewControllers(self.viewControllerList, direction: .forward, animated: true, completion: nil)
    }
    
    func updateDataAlert() {
        let alert = UIAlertController(title: "Reload data", message: "Data hasn't been updated for more than \(self.updateInterval) minutes, do you wan't to update the data?", preferredStyle: UIAlertControllerStyle.alert)
        let submitAction = UIAlertAction(title: "Reload", style: UIAlertActionStyle.default, handler: { (_) in
            do {
                try self.reloadData()
            } catch {
                print(error)
            }
        })
        let skipAction = UIAlertAction(title: "Skip", style: UIAlertActionStyle.default, handler: { (_) in

        })
        alert.addAction(submitAction)
        alert.addAction(skipAction)
        if ((self.presentedViewController as? UIAlertController) == nil) {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if isLoadingPage {
            return
        }
        switch self.dataStatus {
        case .reload:
            do {
                try reloadData()
            } catch {
                print(error)
            }
            break
        case .update:
            self.updateDataAlert()
            break
        default:
            break
        }
    }
    
    func prepareNextPage() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tableVC = storyboard.instantiateViewController(withIdentifier: "TableVC") as! MainTableViewController
        tableVC.page = self.page
        tableVC.perPage = self.perPage
        tableVC.pageId = self.viewControllerList.count
        
        tableVC.userIdExpr = self.idExpr
        tableVC.pageIdExpr = self.pageIdExpr
        tableVC.usernameExpr = self.usernameExpr
        //tableVC.dataStatus = self.dataStatus
        
//        tableVC.allDevelopers = self.developers
        self.viewControllerList.append(tableVC)
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
       
        if self.isLoadingPage {
            return nil
        }
        
        guard let vcIndex = self.viewControllerList.index(of: viewController) else {
            return nil
        }
        
        let previousPage = vcIndex - 1
        
        guard previousPage >= 0 else {
            return nil
        }
        
        return self.viewControllerList[previousPage]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {

        if self.isLoadingPage {
            return nil
        }
        
        guard let vcIndex = self.viewControllerList.index(of: viewController) else {
            return nil
        }
        
        let nextPage = vcIndex + 1
        
        if nextPage >= self.viewControllerList.count {
            prepareNextPage()
            
            //self.setViewControllers([self.viewControllerList.last!], direction: .forward, animated: true, completion: nil)
            return self.viewControllerList.last
        }
        
        return self.viewControllerList[nextPage]
    }
}
