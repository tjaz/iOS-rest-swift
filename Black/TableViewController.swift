//
//  ViewController.swift
//  Black
//
//  Created by Tjaz Hrovat on 25/11/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import UIKit
import NetworkKit

public struct UserDetails {
    let avatar: UIImage
    let name: String?
    let location: String?
    let company: String?
    let blog: String?
    let email: String?
    let public_repos: Int
    let followers: Int
    let created_at: String
    let isPhone: Bool
}

class TableViewController: UITableViewController {
    
    enum ParseError: Error {
        case invalidFormat(reason: String)
    }
    
    enum UserInterfaceIdiom {
        case usnigned
        
        case phone
        case pad
    }
    
    struct UserCodable: Codable {
        let login: String
        let avatar_url: String
        let created_at: String
    }
    
    struct MainCellItem {
        let userURL: URL
        let avatar: UIImage
        let username: String
        let registered: Date
    }
    
    struct UserDetailsCodable : Codable {
        let name: String?
        let company: String?
        let blog: String?
        let location: String?
        let email: String?
        let public_repos: Int
        let followers: Int
        let created_at: String
    }
    
    @IBOutlet var mainTable: UITableView!
    var tableItems: [MainCellItem] = [MainCellItem]()
    
    var isLoadingItems = false
    var isOverTheEdge = false
    
    var page = 1
    let perPage = 10
    
    public func addNewCell(userItem: UserItem) throws -> Void {
        
        let decoder = JSONDecoder()
        
        let userData = try Data(contentsOf: userItem.url)
        let userCodable = try decoder.decode(UserCodable.self, from: userData)
        print(userCodable.login)
        
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        guard let date = dateFormater.date(from: userCodable.created_at) else {
            throw ParseError.invalidFormat(reason: "can't parse date string or invalid date format.")
        }
        print(date.description)
        
        guard let imageURL = URL(string: userCodable.avatar_url) else {
            throw BackendError.urlError(reason: "invalid URL for avatar image.")
        }
        let imageData = try Data(contentsOf: imageURL)
        guard let avatar = UIImage(data: imageData) else {
            throw ParseError.invalidFormat(reason: "could not convert to image from image data.")
        }
        self.tableItems.append( MainCellItem(userURL: userItem.url, avatar: avatar, username: userCodable.login, registered: date) )
        let index: IndexPath = IndexPath(indexes: [0, self.tableItems.count-1])
        self.page += 1
        DispatchQueue.main.async {            
            self.mainTable.insertRows(at: [index], with: .fade)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.     
        
        self.isLoadingItems = true
        Networking.requestJavaDevelopers(page: page, perPage: perPage, returnUser: addNewCell) { (error) in
            self.isLoadingItems = false
            if let error = error {
                print(error)
                guard ((error as? BackendError) != nil) else {
                    return
                }
                return
            }
            print("completed!")
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.tableView.contentOffset.y < 0 || self.isLoadingItems {
            return
        }
        if self.isOverTheEdge && self.tableView.contentOffset.y >= (self.tableView.contentSize.height - self.tableView.bounds.height) {
            self.isOverTheEdge = false
        }
        else if !self.isOverTheEdge && self.tableView.contentOffset.y >= (self.tableView.contentSize.height - self.tableView.bounds.height) {
            self.isLoadingItems = true
            Networking.requestJavaDevelopers(page: page, perPage: perPage, returnUser: addNewCell) { (error) in
                self.isLoadingItems = false
                self.isOverTheEdge = true
                if let error = error {
                    print(error)
                    guard ((error as? BackendError) != nil) else {
                        return
                    }
                    return
                }
                print("completed!")
            }
        }
        
    }
    
    var userDetails: UserDetails?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //self.performSegue(withIdentifier: "openInfoSegue", sender: tableView.cellForRow(at: indexPath))
        
        DispatchQueue.global(qos: .background).async {
            let decoder = JSONDecoder()
            do {
                let tableItem = self.tableItems[indexPath.row]
                let userData = try Data(contentsOf: tableItem.userURL, options: [])
                let userCodable = try decoder.decode(UserDetailsCodable.self, from: userData)
                
                let isPhone: Bool!
                if UIDevice.current.userInterfaceIdiom == .phone {
                    isPhone = true
                } else {
                    isPhone = false
                }
                
                self.userDetails = UserDetails(avatar: self.tableItems[indexPath.row].avatar, name: userCodable.name, location: userCodable.location, company: userCodable.company, blog: userCodable.blog, email: userCodable.email, public_repos: userCodable.public_repos, followers: userCodable.followers, created_at: userCodable.created_at, isPhone: isPhone)
            } catch {
                print(error)
            }
            DispatchQueue.main.async {
                guard let loading = self.navigationController!.topViewController else {
                    return
                }
                                
                loading.dismiss(animated: true, completion: nil)
                self.navigationController!.topViewController!.performSegue(withIdentifier: "showUserDetails", sender: self)
                
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination
        if let info = destination as? UserInfoViewController {
            let avatar = self.userDetails!.avatar
            let followers = String(self.userDetails!.followers)
            
            let names = ["Name", "Location", "Company", "Email", "Blog", "Public repos"]
            
            var name = self.userDetails!.name
            if name == nil {
                name = ""
            }
            
            var location = self.userDetails!.location
            if location == nil {
                location = ""
            }
            
            var company = self.userDetails!.company
            if company == nil {
                company = ""
            }
            
            var blog = self.userDetails!.blog
            if blog == nil {
                blog = ""
            }
            
            var email = self.userDetails!.email
            if email == nil {
                email = ""
            }
            
            let values = [name!, location!, company!, email!, blog!, String(self.userDetails!.public_repos)]
            
            info.userData = UserInfoData(names: names, values: values, avatar: avatar, followers: followers, iPhone: self.userDetails!.isPhone)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.mainTable.dequeueReusableCell(withIdentifier: "mainTableCell") as! MainTableViewCell
        
        cell.avatarImage.image = self.tableItems[indexPath.row].avatar
        cell.usernameLabel.text = self.tableItems[indexPath.row].username
        
        let date = self.tableItems[indexPath.row].registered
        let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
        
        let day = Calendar.current.component(.day, from: date)
        let month = Calendar.current.component(.month, from: date)
        let year = Calendar.current.component(.year, from: date)
        // 5 february 2017
        cell.registeredDateLabel.text = "\(day) \(months[month-1]) \(year)"
        
        return cell
    }
    
}

