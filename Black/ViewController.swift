//
//  ViewController.swift
//  Black
//
//  Created by Tjaz Hrovat on 11/11/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import UIKit

enum UIUserInterfaceIdiom : Int {
    case unspecified
    
    case phone // iPhone and iPod touch style UI
    case pad   // iPad style UI
}

class UserInfo : NSObject
{
    let url: URL
    let username: String
    let registered: Date
    let avatar: UIImage
    
    required init(url: URL,  _ username: String, _ created: Date, _ avatarImage: UIImage) {
        self.url = url
        self.username = username
        self.registered = created
        self.avatar = avatarImage
    }
}

struct DetailedUserInfo: Codable
{
    let type: String
    let name: String?
    let company: String?
    let location: String
    let email: String?
    let following: Int
}

struct CollectedUserInfo {
    let avatar: UIImage
    let type: String
    let name: String
    let company: String // optional
    let location: String
    let email: String // optional
    let following: Int
    let isPhone: Bool
}

class TableViewController: UITableViewController {

    struct ResponseData: Codable {
        let total_count: Int
        let incomplete_results: Int
        let items: [Item]
    }
    
    struct Item: Codable {
        let url: String
    }
    
    struct User: Codable {
        let login: String
        let avatar_url: String
        let created_at: String
    }
    
    enum BackendError: Error {
        case urlError(reason: String)
//        case objectSerialization(reason: String)
    }
    
    let searchUsersUrl = "https://api.github.com/search/users"
    
    let perPage = 10
    var nextPageCount = 1
    var nextPageURL = ""
    
    func pullUserData(completionHandler: @escaping ([UserInfo]?, Error?) -> Void) {
        guard let url = URL(string: nextPageURL) else { return }
        let session = URLSession(configuration: URLSessionConfiguration.ephemeral, delegate: nil, delegateQueue: OperationQueue.current)
        
        session.dataTask(with: url) { (data, response, error) in
            do {
                if let responseHeader = response as? HTTPURLResponse {
                    
                    print(responseHeader)
                }
                
                if let responseData = data {
                    let decoder = JSONDecoder()
                    let root = try decoder.decode(ResponseData.self, from: responseData)
                    
                    var users = [UserInfo]()
                    for item in root.items {
                        
                        guard let itemURL = URL(string: item.url) else {
                            completionHandler(nil, BackendError.urlError(reason: "invalid url for user"))
                            return
                        }
                        let userData = try Data(contentsOf: itemURL)
                        let user = try decoder.decode(User.self, from: userData)
                        
                        guard let avatarURL = URL(string: user.avatar_url) else {
                            completionHandler(nil, BackendError.urlError(reason: "invalid avatar url"))
                            return
                        }
                        let avatarData = try Data(contentsOf: avatarURL)
                        let avatar = UIImage(data: avatarData)!
                        
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                        let date = dateFormatter.date(from: user.created_at)!
                        
                        let userInfo: UserInfo = UserInfo(url: itemURL, user.login, date, avatar)
                        users.append(userInfo)
                        
                        print(user.login)
                        print(user.created_at)
                    }
                    completionHandler(users, nil)
                }
            } catch {
                print("error trying to convert data to JSON")
                completionHandler(nil, error)
            }
            
        }.resume()
    }
    
    func newRequest() {
        
        formNewURL(withPageNum: self.nextPageCount)
        
        pullUserData() { (cells, error) in
            if error != nil {
                print(error!)
                return
            }
            self.performSelector(onMainThread: #selector(self.addNewItems), with: cells!, waitUntilDone: false)
        }

    }
    
    func formNewURL(withPageNum num: Int) {
        self.nextPageURL = searchUsersUrl + "?q=language:java&page=\(num*perPage)&per_page=\(perPage)"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()       
        newRequest()
    }
    
    var lastContentHeight:CGFloat = 0.0
    var isDidScrollLocked:Bool = false
    
    var cellItems: [UserInfo] = [UserInfo]()
    
    let cellHeight = 100

    @objc func addNewItems(cells: [UserInfo]) {
        self.cellItems += cells
        self.isDidScrollLocked = false
        self.lastContentHeight = self.tableView.contentSize.height
        self.tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = Bundle.main.loadNibNamed("TableViewCell", owner: self, options: nil)?.first as! TableViewCell
        
        if indexPath.row < cellItems.count {
            cell.mainImageView.image = cellItems[indexPath.row].avatar
            
            let date = cellItems[indexPath.row].registered
            let calendar = Calendar.current
            let year = calendar.component(.year, from: date)
            let month = calendar.component(.month, from: date)
            let day = calendar.component(.day, from: date)
            
            cell.registeredLabel.text = "\(day). \(month). \(year)"
            cell.usernameLabel.text = cellItems[indexPath.row].username
        }
        
        return cell
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.tableView.contentOffset.y<0 || self.lastContentHeight >= self.tableView.contentSize.height || self.isDidScrollLocked {
            return
        }
        
        if self.tableView.contentOffset.y >= (self.tableView.contentSize.height - self.tableView.bounds.size.height)
        {
            self.isDidScrollLocked = true
            
            //print("did scroll")
            self.nextPageCount += 1
            self.newRequest()
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(cellHeight)
    }
    
    // open a detailed view for user information
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {        
        
        let decoder = JSONDecoder()
        do {
            let userData = try Data(contentsOf: cellItems[indexPath.row].url)
            let userInfo = try decoder.decode(DetailedUserInfo.self, from: userData)
            
            let avatar = self.cellItems[indexPath.row].avatar
            
            let name: String!
            if userInfo.name == nil {
                name = ""
            } else {
                name = userInfo.name
            }
            
            let company: String!
            if userInfo.company == nil {
                company = ""
            } else {
                company = userInfo.company!
            }
            
            let mail: String!
            if userInfo.email == nil {
                mail = "test@test.si"
            } else {
                mail = userInfo.email!
            }
            
            let isPhone: Bool!
            if UIDevice.current.userInterfaceIdiom == .pad {
                isPhone = false
            } else {
                isPhone = true
            }
            
            let collectedInfo: CollectedUserInfo = CollectedUserInfo(avatar: avatar, type: userInfo.type, name: name, company: company, location: userInfo.location, email: mail, following: userInfo.following, isPhone: isPhone)
           
            
            let userInfoController = Bundle.main.loadNibNamed("UserInfoViewController", owner: self, options: nil)?.first as! UserInfoViewController
            userInfoController.updateCellInformation(userInfo: collectedInfo)
            
            self.navigationController!.pushViewController(userInfoController, animated: true)
        }
        catch {
            print(error)
        }
        
    }
}

