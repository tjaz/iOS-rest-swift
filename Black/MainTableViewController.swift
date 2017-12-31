//
//  MainTableViewController.swift
//  Black
//
//  Created by Tjaz Hrovat on 25/12/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import UIKit
import GithubConnectKit
import CoreData

class MainTableViewController: UITableViewController {
    enum BackendError: Error {
        case parseError(reason: String)
    }
    
    enum DataRecordStatus {
        case reload
        case update
        case new
    }
    
    struct UserCodable: Codable {
        let login: String
        let avatar_url: String
        let created_at: String
    }
    @IBOutlet weak var reloadItem: UIBarButtonItem!
    
    var developers = [JavaDeveloper]()
    let numOfPages = 10
    var page: Int {
        return self.developers.count + 1
    }
    var perPage: Int {
        return self.numOfPages - self.developers.count % self.numOfPages
    }
    
    let upperTimeBoundInMinutes = 15
    let lowerTimeBoundInMinutes = 2
    var dataRecordStatus:DataRecordStatus = .reload
    var isLoading = false
    var isScrollOverTheEdge = false
    
    @IBAction func onReloadPressed(_ sender: Any) {
        self.reloadDevelopers()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            let fetchDataRecord: NSFetchRequest<DataRecord> = DataRecord.fetchRequest()
            let dataRecords = try PersistentStorage.context.fetch(fetchDataRecord)
            if dataRecords.count == 0 {
                let dataRecord = DataRecord(context: PersistentStorage.context)
                dataRecord.created = NSDate(timeIntervalSince1970: NSTimeIntervalSince1970)
                PersistentStorage.saveContext()
                
                self.loadMoreDevelopers(completionHandler: { (error) in
                    if let error = error {
                        print(error)
                        return
                    }
                })
                
            } else {
                let fetchJavaDevelopers: NSFetchRequest<JavaDeveloper> = JavaDeveloper.fetchRequest()
                self.developers = try PersistentStorage.context.fetch(fetchJavaDevelopers)
            }
        } catch {
            print(error)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !self.isLoading {
            do {
                try self.checkUserData()
                if self.dataRecordStatus == .reload {
                    print("RELOAD")
                    self.triggerReloadAlert()
                } else if (self.dataRecordStatus == .update) {
                    print("UPDATE")
                }
            } catch {
                print(error)
            }
        }
    }
    
    func triggerReloadAlert() {
        let alert = UIAlertController(title: "Reload data", message: "Data hasn't been updated for more than \(self.upperTimeBoundInMinutes) minutes, do you wan't to update your data?", preferredStyle: UIAlertControllerStyle.alert)
        let reloadAction = UIAlertAction(title: "Reload", style: UIAlertActionStyle.default) { (_) in
            self.reloadDevelopers()
        }
        let refuseAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: nil)
        alert.addAction(reloadAction)
        alert.addAction(refuseAction)
        self.present(alert, animated: false, completion: {
            let shakeAnimation = CABasicAnimation(keyPath: "position")
            shakeAnimation.fromValue = CGPoint(x: alert.view.center.x - 5, y: alert.view.center.y)
            shakeAnimation.toValue = CGPoint(x: alert.view.center.x + 5, y: alert.view.center.y)
            shakeAnimation.duration = 0.1
            shakeAnimation.repeatCount = 3
            shakeAnimation.autoreverses = true
            alert.view.layer.add(shakeAnimation, forKey: "shake")
        })
    }
    
    func checkUserData() throws {
        
        let fetchDataRecord: NSFetchRequest<DataRecord> = DataRecord.fetchRequest()
        let dataRecords = try PersistentStorage.context.fetch(fetchDataRecord)
        
        let interval:Double = Date().timeIntervalSince(dataRecords[0].created as Date!)
        let elapsedTimeInMinutes = Int64(interval) / 60
        
        if elapsedTimeInMinutes > self.upperTimeBoundInMinutes {
            print("UPPER DATA TIME BOUND HIT \(elapsedTimeInMinutes)")
            self.dataRecordStatus = .reload
            self.reloadItem.isEnabled = true
        } else if (elapsedTimeInMinutes > lowerTimeBoundInMinutes) {
            print("LOWER DATA TIME BOUND HIT \(elapsedTimeInMinutes)")
            self.dataRecordStatus = .update
            self.reloadItem.isEnabled = true
        }
        else {
            let fetchJavaDevelopers: NSFetchRequest<JavaDeveloper> = JavaDeveloper.fetchRequest()
            self.developers = try PersistentStorage.context.fetch(fetchJavaDevelopers)
        }
    }
    
    func reloadDevelopers() {
        do {
            let fetchJavaDevelopers: NSFetchRequest<JavaDeveloper> = JavaDeveloper.fetchRequest()
            self.developers = try PersistentStorage.context.fetch(fetchJavaDevelopers)
            for developer in self.developers  {
                PersistentStorage.context.delete(developer)
            }
            PersistentStorage.saveContext()
            self.developers = []
            self.tableView.reloadData()
            
            loadMoreDevelopers(completionHandler: { (error) in
                if let error = error {
                    print(error)
                    return
                }
                print("DONE RELOADING")
            })
        } catch {
            print(error)
        }
    }
    
    func loadMoreDevelopers(completionHandler: @escaping (Error?) -> Void) {
        self.isLoading = true
        self.reloadItem.isEnabled = false
        
        Rest.getJavaDevelopers(page: self.page, perPage: self.perPage, userCallback: { (userURL) in
            print("NEW USER")
            let decoder = JSONDecoder()
            
            let userData = try Data(contentsOf: userURL)
            let userDecoded = try decoder.decode(UserCodable.self, from: userData)
            
            guard let avatarURL = URL(string: userDecoded.avatar_url) else {
                throw NetworkingError.urlError(reason: "Invalid avatar url.")
            }
            let avatarData = try Data(contentsOf: avatarURL)
            
            let dateFormater = DateFormatter()
            dateFormater.dateFormat = "yyyy-MM-dd'T'HH.mm.ssz"
            guard let registeredDate = dateFormater.date(from: userDecoded.created_at) else {
                throw BackendError.parseError(reason: "Error while parsing date from a given date text: " + userDecoded.created_at)
            }
            
            let developer = JavaDeveloper(context: PersistentStorage.context)
            developer.avatar = avatarData as NSData
            developer.registered = registeredDate as NSDate
            developer.username = userDecoded.login
            developer.url = userURL
            
            PersistentStorage.saveContext()
            
            DispatchQueue.main.async {
                // update cells
                self.developers.append(developer)
                let indexPath = IndexPath(row: self.developers.count-1, section: 0)
                self.tableView.insertRows(at: [indexPath], with: UITableViewRowAnimation.fade)
            }
            
            print(userDecoded.login)
        }) { (error) in
            self.isLoading = false
            
            if let error = error {
                self.dataRecordStatus = .reload
                self.reloadItem.isEnabled = true
                completionHandler(error)
                return
            }
            self.dataRecordStatus = .new
            DispatchQueue.main.async {
                do {
                    let fetchDataRecord: NSFetchRequest<DataRecord> = DataRecord.fetchRequest()
                    let dataRecord = try PersistentStorage.context.fetch(fetchDataRecord)[0]
                    dataRecord.created = NSDate()
                    PersistentStorage.saveContext()
                } catch {
                    completionHandler(error)
                    self.dataRecordStatus = .reload
                    self.reloadItem.isEnabled = true
                }
            }
            
            print("COMPLETE")
            completionHandler(nil)
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.tableView.bounds.size.height / CGFloat(self.numOfPages)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.developers.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "developerCell", for: indexPath) as! MainTableViewCell
        cell.avatarImage.layer.cornerRadius = 10
        cell.avatarImage.clipsToBounds = true
        
        let developer = self.developers[indexPath.row]
        
        if let avatarData = developer.avatar as Data? {
            cell.avatarImage.image = UIImage(data: avatarData)
        }
        
        cell.avatarImage.bounds = CGRect(x: 0, y: 0, width: 10 * 2, height: 10 * 2)
        
        cell.usernameLabel.text = developer.username
        
        let day = Calendar.current.component(Calendar.Component.day, from: developer.registered! as Date)
        let month = Calendar.current.component(Calendar.Component.month, from: developer.registered! as Date)
        let year = Calendar.current.component(Calendar.Component.year, from: developer.registered! as Date)
        let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
        cell.registeredLabel.text = "\(day) \(months[month-1]) \(year)"

        return cell
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.isLoading {
            return
        }
        do {
            if scrollView.contentOffset.y < 0  || (self.isScrollOverTheEdge && scrollView.contentOffset.y < (scrollView.contentSize.height - scrollView.bounds.size.height)){
                self.isScrollOverTheEdge = false
                
            } else if !self.isScrollOverTheEdge && scrollView.contentOffset.y > (scrollView.contentSize.height - scrollView.bounds.size.height) {
                print("SCROLL OVER THE EDGE")
                self.isScrollOverTheEdge = true
                try self.checkUserData()
                switch self.dataRecordStatus {
                case .reload:
                    self.triggerReloadAlert()
                    break
                default:
                    self.loadMoreDevelopers(completionHandler: { (error) in
                        if let error = error {
                            print(error)
                        }
                    })
                }
            }
        } catch {
            print(error)
            return
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let loadingController = segue.destination as? LoadingViewController {
            loadingController.developer = developers[self.tableView.indexPathForSelectedRow!.row]
        }
    }


    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

}
