//
//  MainTableViewController.swift
//  Black
//
//  Created by Tjaz Hrovat on 14/12/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import UIKit
import GithubKit
import CoreData

enum BackendError: Error {
    case storageError(reason: String)
    case dataError(reason: String)
}

class MainTableViewController: UITableViewController {
    
    enum ReloadUsers {
        case noReload
        case partialReload
        case reload
    }
    
    struct UserCodable: Codable {
        let login: String
        let avatar_url: String
        let created_at: String
    }
    
    var reload: ReloadUsers = ReloadUsers.reload
    
    var page: Int {
        return self.developers.count + 1
    }
    let numberOfPages: Int = 10
    var perPage: Int {
        let deviation = self.developers.count % self.numberOfPages
        if deviation == 0 {
            return numberOfPages
        }
        return self.numberOfPages - deviation
    }
    @IBOutlet weak var notificationItem: UIBarButtonItem!
    
    var developers = [JavaDeveloper]()
    var isScrollerAtTheEnd = false
    var isLoadingData = false
    
    @IBAction func onRefreshTapped(_ sender: Any) {
        if !self.isLoadingData {
            self.reloadUserData(completionHandler: { (error) in
                if let error = error {
                    print(error)
                    return
                }
                print("SUCCESSFULLY RELOADED DATA")
            })
        }
    }
    
    let obsoleteDataMinutes = 5
    let partialyObsoleteDataMinutes = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try checkUserData()

        } catch {
            print(error)
            return
        }
        
        switch reload {
        case .reload:
            if self.developers.count == 0 {
                reloadUserData(completionHandler: { (error) in
                    if let error = error {
                        print(error)
                        return
                    }
                    print("SUCCESSFULLY LOADED USERS ON APPLICATION START")
                })
            }
            break
        default:
            break
        }
    }
    
    func triggerReloadDialog() {
        let alert = UIAlertController(title: "Reload data", message: "Data hasn't been updated for more than \(obsoleteDataMinutes) minutes, do you wan't to update your data?", preferredStyle: UIAlertControllerStyle.alert)
        let reloadAction = UIAlertAction(title: "Reload", style: UIAlertActionStyle.default) { (_) in
            
            self.reloadUserData(completionHandler: { (error) in
                if let error = error {
                    print(error)
                    return
                }
                print("SUCCESSULLY RELOADED DATA FROM DIALOG")
            })
        }
        let refuseAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: nil)
        alert.addAction(reloadAction)
        alert.addAction(refuseAction)
        self.present(alert, animated: false) {
            print("NOTIFICATION PRESERTED")
            let animation = CABasicAnimation(keyPath: "position")
            animation.fromValue = CGPoint(x: alert.view.center.x - 5, y: alert.view.center.y)
            animation.toValue = CGPoint(x: alert.view.center.x + 5, y: alert.view.center.y)
            animation.duration = 0.08
            animation.repeatCount = 5
            animation.autoreverses = true
            alert.view.layer.add(animation, forKey: "shake")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        do {
            if !self.isLoadingData {
                try checkUserData()
                
                switch self.reload {
                case .noReload, .partialReload: break
                default:
                    triggerReloadDialog()
                }
            }
        } catch {
            print(error)
        }
    }
    
    func checkUserData() throws -> Void {
        
        let fetchRequestDevelopers: NSFetchRequest<JavaDeveloper> = JavaDeveloper.fetchRequest()
        
        let developers = try PersistentStorage.context.fetch(fetchRequestDevelopers)
        self.developers = developers
        
        let fetchRequestData: NSFetchRequest<DataInformation> = DataInformation.fetchRequest()
        let info = try PersistentStorage.context.fetch(fetchRequestData)
        let dataRecordCreated: DataInformation!
        
        if info.count > 0 {
            dataRecordCreated = info[0]
        } else {
            dataRecordCreated = DataInformation(context: PersistentStorage.context)
            dataRecordCreated.creation = NSDate(timeIntervalSince1970: NSTimeIntervalSince1970)
            PersistentStorage.saveContext()
        }
        
        let interval:Double = Date().timeIntervalSince(dataRecordCreated.creation as Date!)
        let elapsedTimeInMinutes = Int64(interval) / 60
        print("ELAPSED DATA TIME \(elapsedTimeInMinutes)")
        if developers.count < numberOfPages || Int64(self.obsoleteDataMinutes) < elapsedTimeInMinutes {
            reload = .reload
            self.notificationItem.isEnabled = true
            print("RELOAD")
        } else if partialyObsoleteDataMinutes < elapsedTimeInMinutes {
            reload = .partialReload
            self.notificationItem.isEnabled = true
            print("PARTIALY RELOAD")
        } else {
            reload = .noReload
            print("NO NEED TO RELOAD")
        }
    }
    
    func reloadUserData(completionHandler: @escaping (Error?) -> Void) {
        for developer in developers {
            PersistentStorage.context.delete(developer)
        }
        PersistentStorage.saveContext()
        self.developers = []
        self.tableView.reloadData()
        
        getJavaDevelopers(completionHandler: { (error) in
            do {
                if let error = error {
                    self.reload = .reload
                    throw error
                }
                self.reload = ReloadUsers.noReload
                
                let fetchRequestData: NSFetchRequest<DataInformation> = DataInformation.fetchRequest()
                let records = try PersistentStorage.context.fetch(fetchRequestData)
                let dataRecord = records[0]
                dataRecord.creation = NSDate()
                PersistentStorage.saveContext()
                
                completionHandler(nil)
            } catch {
                completionHandler(error)
            }
            
        })
    }
    
    func getJavaDevelopers(completionHandler: @escaping (Error?) -> Void) {
        self.isLoadingData = true
        if self.reload != .noReload {
            self.notificationItem.isEnabled = false
        }
        
        GithubNetworking.getUsers(page: self.page, perPage: self.perPage, userCallback: {userURL in
            print("NEW USER")
            
            let decoder = JSONDecoder()
            let userData = try Data(contentsOf: userURL)
            let userDecoded = try decoder.decode(UserCodable.self, from: userData)
            
            guard let avatarURL = URL(string: userDecoded.avatar_url) else {
                throw NetworkingError.invalidUrl(reason: "invalid url for avatar image.")
            }
            let avatarData = try Data(contentsOf: avatarURL)
            
            let formater = DateFormatter()
            formater.dateFormat = "yyyy-MM-dd'T'HH.mm.ssz"
            guard let registeredDate = formater.date(from: userDecoded.created_at) else {
                throw BackendError.dataError(reason: "Can't covert date string into Date.")
            }
            
            let developer = JavaDeveloper(context: PersistentStorage.context)
            developer.url = userURL
            developer.avatar = avatarData as NSData
            developer.username = userDecoded.login
            developer.registered = registeredDate as NSDate
            
            PersistentStorage.saveContext()
            
            print(developer.username!)
            
            self.developers.append(developer)
            
            let indexPath = IndexPath(row: self.developers.count-1, section: 0)
            
            DispatchQueue.main.async {
                self.tableView.insertRows(at: [indexPath], with: UITableViewRowAnimation.fade)
            }
            
        }) { (error) in
            self.isLoadingData = false
            if self.reload != .noReload {
                DispatchQueue.main.async {
                    self.notificationItem.isEnabled = true
                }
            }
            
            if let error = error {
                completionHandler(error)
                return
            }
            print("COMPLETE")
            completionHandler(nil)
        }
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.developers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as! MainTableViewCell
        
        // Configure the cell...
        let developer = developers[indexPath.row]
        if let avatarData = developer.avatar as Data? {
            cell.avatarImage.image = UIImage(data: avatarData)
        }
        cell.usernameLabel.text = developer.username
        let date = developer.registered as Date?
        let day = Calendar.current.component(Calendar.Component.day, from: date!)
        let month = Calendar.current.component(Calendar.Component.month, from: date!)
        let year = Calendar.current.component(Calendar.Component.year, from: date!)
        let months = ["January", "February", "March", "April", "May", "June", "July", "August", "Septmeber", "October", "November", "December"]
        cell.registeredLabel.text = "\(day) \(months[month-1]) \(year)"
        
        return cell
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < 0 || self.isLoadingData {
            return
        }
        
        if self.isScrollerAtTheEnd && scrollView.contentOffset.y < (scrollView.contentSize.height - scrollView.bounds.size.height) {
            self.isScrollerAtTheEnd = false
        }
        else if !self.isScrollerAtTheEnd && scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.bounds.size.height) {
            
            self.isScrollerAtTheEnd = true
            print("OVER THE EDGE")
            
            do {
                try checkUserData()
            } catch {
                print(error)
                return
            }
            switch reload {
            case .reload:
                triggerReloadDialog()
                break
            default:
                getJavaDevelopers(completionHandler: { (error) in
                    
                    if let error = error {
                        print(error)
                        return
                    }
                })
                break
            }
        }
    }
    
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//
//    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let userVC = (segue.destination as? UserTableViewController) {
            userVC.developer = developers[self.tableView.indexPathForSelectedRow!.row]
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
