//
//  MainTableViewController.swift
//  Black
//
//  Created by Tjaz Hrovat on 05/01/2018.
//  Copyright © 2018 Tjaz Hrovat. All rights reserved.
//

import UIKit
import GithubConnectKit
import SQLite
import CoreData

class MainTableViewController: UITableViewController {
    enum BackendError: Error {
        case parseError(reason: String)
    }
        
    struct UserCodable: Codable {
        let login: String
        let avatar_url: String?
        let created_at: String
    }
    
    struct TmpJavaDeveloper {
        var username: String?
        var avatar: NSData?
        var registered: NSDate?
        var url: URL?
    }
    
    var page: Int = 0
    var perPage: Int = 0
    var pageId: Int = 0
    
    var userIdExpr: Expression<Int>!
    var pageIdExpr: Expression<Int>!
    var usernameExpr: Expression<String>!
    public var isPageLoaded = false
    
    var userTable: Table {
        let rootVC = self.parent! as! RootPageViewController
        return rootVC.userTable
    }
    var dataStatus: DataStatus {
        let rootVC = self.parent! as! RootPageViewController
        return rootVC.dataStatus
    }
    
    var sortedDevelopers = [JavaDeveloper]()
    var tmpDevelopers = [TmpJavaDeveloper]()

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func updateDataStatus()throws -> Void {
        let rootVC = self.parent! as! RootPageViewController
        try rootVC.updateDataStatus()
    }
    
    func loadData() {
        if !self.isPageLoaded {
            do {
                let rootVC = self.parent! as! RootPageViewController
                if dataStatus != .reload {
                    try self.updateDataStatus()
                }
                switch self.dataStatus {
                case .new, .update:
                    try self.sortUsersByName()
                    if self.sortedDevelopers.count == 0  {
                        if self.dataStatus == .new {
                            self.loadNewUsers(completionHandler: { (error) in
                                if let error = error {
                                    print(error)
                                }
                            })
                        } else {
                            
                            rootVC.isLoadingPage = false
                            DispatchQueue.main.async {
                                rootVC.setViewControllers([rootVC.viewControllerList[self.pageId-1]], direction: .reverse, animated: true, completion: { (_) in
                                    rootVC.viewControllerList.removeLast()
                                })
                            }
                        }
                    } else {
                        self.tableView.reloadData()
                        self.isPageLoaded = true
                        let rootVC = self.parent! as! RootPageViewController
                        rootVC.isLoadingPage = false
                    }
                    break
                case .reload:
                    self.loadNewUsers(completionHandler: { (error) in
                        if let error = error {
                            print(error)
                        }
                    })
                    break
                }
            } catch {
                print(error)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("PAGE: \(self.pageId)")
        self.loadData()
        
        if self.dataStatus == .update {
            if self.pageId != 0 {
                let rootVC = self.parent! as! RootPageViewController
                rootVC.updateDataAlert()
            }
        }
    }
    
    func triggerErrorAlert(error: Error) {
        let rootVC = self.parent! as! RootPageViewController
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
        let confirmAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { (_) in
            rootVC.viewControllerList.removeLast()
            rootVC.isLoadingPage = false
            if rootVC.viewControllerList.count == 0 {
                rootVC.dataStatus = .reload
                rootVC.prepareNextPage()
                do {
                    try rootVC.reloadData()
                } catch {
                    print(error)
                }
            } else {
                rootVC.setViewControllers([rootVC.viewControllerList[self.pageId-1]], direction: .reverse, animated: true, completion: nil)
            }
            
        })
        alert.addAction(confirmAction)
        rootVC.present(alert, animated: true, completion: nil)
    }
    
    func loadNewUsers(completionHandler: @escaping (Error?) -> Void) {
        
        Rest.getJavaDevelopers(page: self.page, perPage: self.perPage, userCallback: { (userURL) in            
            
            print("NEW USER")
            let decoder = JSONDecoder()
            let userData = try Data(contentsOf: userURL)
            let userDecoded = try decoder.decode(UserCodable.self, from: userData)
            var developer = TmpJavaDeveloper()
            developer.url = userURL
            
            if userDecoded.avatar_url != nil {
                guard let avatarURL = URL(string: userDecoded.avatar_url!) else {
                    throw NetworkingError.urlError(reason: "Invalid avatar url.")
                }
                developer.avatar = try Data(contentsOf: avatarURL) as NSData
            }
            
            let dateFormater = DateFormatter()
            dateFormater.dateFormat = "yyyy-MM-dd'T'HH.mm.ssz"
            guard let registeredDate = dateFormater.date(from: userDecoded.created_at) else {
                throw BackendError.parseError(reason: "Error while parsing date from a given date text: " + userDecoded.created_at)
            }
            developer.registered = (registeredDate as NSDate)
            developer.username = userDecoded.login
            
            print(developer.username!)
            
            self.tmpDevelopers.append(developer)
            
        }) { (error) in
            if let error = error {
                self.triggerErrorAlert(error: error)
                completionHandler(error)
                return
            }
            
            do {
                let rootVC = self.parent! as! RootPageViewController
                for developer in self.tmpDevelopers {
                    let insertUser = self.userTable.insert(self.pageIdExpr <- self.pageId, self.usernameExpr <- developer.username!)
                    try rootVC.database.run(insertUser)
                    print("SQL: USER INSERTED " + developer.username!)
                    
                    let developerCD = JavaDeveloper(context: PersistentStorage.context)
                    developerCD.avatar = developer.avatar as NSData?
                    developerCD.registered = developer.registered
                    developerCD.username = developer.username
                    developerCD.url = developer.url
                    
                    //PersistentStorage.saveContext()
                    print("CORE DATA: USER INSERTED")

                    PersistentStorage.saveContext()
                    
                    rootVC.developers.append(developerCD)
                }
                
                try self.sortUsersByName()
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    let fetchDataRecord: NSFetchRequest<DataRecord> = DataRecord.fetchRequest()
                    do {
                        if self.pageId == 0 {
                            let dataRecords = try PersistentStorage.context.fetch(fetchDataRecord)
                            let dataRecord = dataRecords[0]
                            dataRecord.created = NSDate()
                            PersistentStorage.saveContext()
                            rootVC.dataStatus = .new
                        }
                        self.isPageLoaded = true
                        rootVC.isLoadingPage = false
                        completionHandler(nil)
                        
                    } catch {
                        rootVC.isLoadingPage = false
                        completionHandler(error)
                    }
                    
                }
                
            } catch {
                let rootVC = self.parent! as! RootPageViewController
                rootVC.isLoadingPage = false
                completionHandler(error)
                return
            }
            
            print("COMPLETE")
        }
    }
    
    func sortUsersByName()throws -> Void {
        let rootVC = self.parent! as! RootPageViewController
        // Orders by uppercase and then by lowercase string names in developer list
        let sortedTable = rootVC.userTable.filter(self.pageIdExpr == self.pageId).order(self.usernameExpr.asc)
        let sortedDevelopersSQL = try rootVC.database.prepare(sortedTable)
        for developer in sortedDevelopersSQL {
            let id = developer[self.userIdExpr]-1
            let rootVC = self.parent! as! RootPageViewController
            self.sortedDevelopers.append( rootVC.developers[id] )
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sortedDevelopers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mainCell", for: indexPath) as! MainTableViewCell
        
        let developer = self.sortedDevelopers[indexPath.row]
        if let avatarData = developer.avatar as Data? {
            cell.avatarImage.image = UIImage(data: avatarData)
        }
        
        let day = Calendar.current.component(.day, from: developer.registered! as Date)
        let month = Calendar.current.component(.month, from: developer.registered! as Date)
        let year = Calendar.current.component(.year, from: developer.registered! as Date)
        let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
        cell.registeredLabel.text = "\(day) \(months[month-1]) \(year)"
        
        cell.usernameLabel.text = developer.username

        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let loadingController = segue.destination as? InfoLoadingViewController {
            let developer = self.sortedDevelopers[self.tableView.indexPathForSelectedRow!.row]
            loadingController.javaDeveloper = developer
        }
    }
}
