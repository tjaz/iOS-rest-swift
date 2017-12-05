//
//  ViewController.swift
//  Black
//
//  Created by Tjaz Hrovat on 02/12/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import UIKit
import NetworkingKit
import CoreData

class MainTableViewController: UITableViewController {
    
    enum BackendError: Error {
        case dataError(reason: String)
        case responseError(reason: String)
    }
    
    struct DeveloperInformationCodable: Codable {
        let name: String?
        let company: String?
        let blog: String?
        let location: String?
        let email: String?
        let public_repos: Int
        let followers: Int
    }
    
    enum UserInterfaceIdiom {
        case unspecified
        
        case phone
        case pad
    }
    
    struct UserCodable: Codable {
        let login: String
        let avatar_url: String
        let created_at: String
    }
   
    var developers: [Developer] = [Developer]()
    
    var page: Int {
        return self.developers.count+1
    }
    var perPage:Int {
        let rounded = self.developers.count % 10
        return 10 - rounded
    }
    
    var isEndOfScroll = false
    var isLoadingData = false
    
    var isFirstTime = true
    
    var alert: UIAlertController? = nil
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let fetchRequest: NSFetchRequest<Developer> = Developer.fetchRequest()
        do {
            // Try to fetch user data from the device storage
            let developers = try PersistentStorage.context.fetch(fetchRequest)
            self.developers = developers
            // If there is no data yet, then load a new user data
            if self.page == 1 {
                self.loadUsers({ (error) -> Void in
                    if let error = error {
                        self.handleError(BackendError.responseError(reason: error.localizedDescription))
                    }
                })
            
            } else {
                self.tableView.reloadData()
            }
        } catch {
            handleError(error)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // If there is data already in the device storage, then refresh table view or load fresh user data
        if self.page > 1 && self.isFirstTime {
            self.isFirstTime = false
            let alert = UIAlertController(title: "Warning", message: "Developer data is obsolete, do you want to reload developer data? ", preferredStyle: UIAlertControllerStyle.alert)
            let actionReload = UIAlertAction(title: "Reload", style: .default, handler: { (_) in
                // Clear all saved users inside device storage.
                for developer in self.developers {
                    PersistentStorage.context.delete(developer)
                }
                self.developers = []
                self.tableView.reloadData()
                // Load fresh users.
                self.loadUsers({ (error) -> Void in
                    if let error = error {
                        self.handleError(BackendError.responseError(reason: error.localizedDescription))
                    }
                })
            })
        
            alert.addAction(actionReload)
            let actionPreserve = UIAlertAction(title: "No", style: .default, handler: nil)
            alert.addAction(actionPreserve)
            self.present(alert, animated: true, completion: nil)
        }
        
        // catch any alerts
        if let alert = self.alert {
            self.present(alert, animated: true, completion: nil)
            self.alert = nil
        }
    }
    
    func handleError(_ error: Error) {
        print(error)
        if error is BackendError {
            let backendError = error as! BackendError
            switch backendError {
            case BackendError.responseError:
                let alert = UIAlertController(title: "Server error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                let action = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
                alert.addAction(action)
                present(alert, animated: true, completion: nil)
                break
            default:
                break
            }
        }
    }
    
    func loadUsers(_ completionHandler: ((Error?) -> Void)? ) {
        GithubConnect.getJavaDevelopers(page: self.page, perPage: self.perPage, userCallback: { (url) in
            print("NEW USER")
            let decoder = JSONDecoder()
            let userData = try Data(contentsOf: url)
            let userDecoded = try decoder.decode(UserCodable.self, from: userData)
            
            guard let avatarURL = URL(string: userDecoded.avatar_url) else {
                throw NetworkingError.urlError(reason: "Invalid avatar url.")
            }
            let avatarData = try Data(contentsOf: avatarURL)
            //let avatarImage = try UIImage(data: avatarData)
            
            let formater = DateFormatter()
            formater.dateFormat = "yyyy-MM-dd'T'HH.mm.ssZ"
            guard let date = formater.date(from: userDecoded.created_at) else {
                throw BackendError.dataError(reason: "Could not parse date data.")
            }
            
            let developer: Developer = Developer(context: PersistentStorage.context)
            developer.avatar = avatarData as NSData
            developer.created = date as NSDate
            developer.username = userDecoded.login
            developer.url = url
            PersistentStorage.saveContext()
            
            self.developers.append(developer)
            let index: IndexPath = IndexPath(indexes: [0, self.developers.count-1])
            print(developer.username!)
            
            DispatchQueue.main.async {
                // insert a new cell with developer into table
                self.tableView.insertRows(at: [index], with: .fade)
            }
            
            
        }) { (error) in
            if let error = error {
                completionHandler!(error)
            }
            completionHandler!(nil)
            print("COMPLETE")
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "mainTableCell") as! MainTableViewCell
        let developer = developers[indexPath.row]
        cell.usernameLabel.text = developer.username
        cell.avatarImage.image = UIImage(data: developer.avatar as Data!)

        let date = developer.created as Date!
        let day = Calendar.current.component(.day, from: date!)
        let month = Calendar.current.component(.month, from: date!)
        let year = Calendar.current.component(.year, from: date!)
        let months = ["January", "February", "March", "April", "May", "June", "July", "Aughust", "September", "October", "November", "December"]
        cell.dateLabel.text = "\(day) \(months[month-1]) \(year)"

        return cell
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < 0 || self.isLoadingData {
            return
        }
        
        if self.isEndOfScroll && scrollView.contentOffset.y < (scrollView.contentSize.height - scrollView.bounds.size.height) {
            self.isEndOfScroll = false
        }
        else if !self.isEndOfScroll && scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.bounds.size.height) {
            print("END OF SCROLL")
            self.isEndOfScroll = true
            self.isLoadingData = true
            
            loadUsers({ (error) -> Void in
                self.isLoadingData = false
                if let error = error {
                    self.handleError(error)
                    return
                }
            })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let controller = segue.destination as? UserViewController {
            //controller.performSegue(withIdentifier: "loading", sender: nil)
            let cell = sender as! MainTableViewCell
            let indexPath = self.tableView.indexPath(for: cell)!
            DispatchQueue.global(qos: .background).async {
                do {
                    let developer = self.developers[indexPath.row]
                    let userURL = developer.url!
                    let userData = try Data(contentsOf: userURL)
                    
                    let decoder = JSONDecoder()
                    let developerDecoded = try decoder.decode(DeveloperInformationCodable.self, from: userData)
                    
                    var name = ""
                    if developerDecoded.name != nil {
                        name = developerDecoded.name!
                    }
                    var company = ""
                    if developerDecoded.company != nil {
                        company = developerDecoded.company!
                    }
                    var blog: URL? = nil
                    if developerDecoded.blog != nil {
                        if let blogURL = URL(string: developerDecoded.blog!) {
                            blog = blogURL
                        } else {
                            print("Warning: could not parse blog url.")
                        }
                    }
                    var location = ""
                    if developerDecoded.location != nil {
                        location = developerDecoded.location!
                    }
                    var email = "test@test.com"
                    if developerDecoded.email != nil {
                        email = developerDecoded.email!
                    }
                    
                    var phone = false
                    if .phone == UIDevice.current.userInterfaceIdiom {
                        phone = true
                    }
                    
                    let avatar = cell.avatarImage
                    
                    controller.attributes = ["Name", "Company", "Location", "Email", "Blog", "Repositories"]
                    controller.values = [name, company, location, email, blog, developerDecoded.public_repos]
                    
                    DispatchQueue.main.async {
                        // force the destination controller view to load
                        let _ = controller.view
                        controller.avatarImage.image = avatar!.image!
                        if !phone {
                            controller.followersLabel.textAlignment = .right
                        }
                        controller.followersLabel.text = "Followers: " + String(developerDecoded.followers)
                        // now remove the loading view controller from the parent view controller
                        controller.isDataLoaded = true
                        controller.dismiss(animated: true, completion: nil)
                        controller.informationTable.reloadData()
                    }
                } catch {
                    self.navigationController?.popViewController(animated: false)
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    let action = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil )
                    alert.addAction(action)
                    self.alert = alert
                    
                    self.handleError(error)
                }
            }
        }
    }
}

