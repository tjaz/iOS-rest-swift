//
//  ViewController.swift
//  Black
//
//  Created by Tjaz Hrovat on 11/11/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import UIKit

class UserInfo : NSObject
{
    let username: String
    let registered: Date
    let avatar: UIImage
    
    required init(_ username: String, _ created: Date, _ avatarImage: UIImage) {
        self.username = username
        self.registered = created
        self.avatar = avatarImage
    }
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
    var nextPageURL = ""
    
    func pullUserData(completionHandler: @escaping ([UserInfo]?, Error?) -> Void) {
        guard let url = URL(string: nextPageURL) else { return }
        let session = URLSession(configuration: URLSessionConfiguration.ephemeral, delegate: nil, delegateQueue: OperationQueue.current)
        
        session.dataTask(with: url) { (data, response, error) in
            do {
                if let responseHeader = response as? HTTPURLResponse {
                    
                    print(responseHeader)
                    self.nextPageURL = ""
                    
                    if let link = responseHeader.allHeaderFields["Link"] as? String {
                        
                        let array = link.components(separatedBy: "rel=\"next\"")
                        if array.count > 1 {
                            let second = array[1]
                            if second.hasPrefix(",") {
                                let open = second.split(separator: "<")[1]
                                let close = open.split(separator: ">")[0]
                                
                                self.nextPageURL = String(close)
                            }
                        }
                    }
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
                        
                        let userInfo: UserInfo = UserInfo(user.login, date, avatar)
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
        pullUserData() { (cells, error) in
            if error != nil {
                print(error!)
                return
            }
            self.performSelector(onMainThread: #selector(self.addNewItems), with: cells!, waitUntilDone: false)
        }

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.nextPageURL = searchUsersUrl + "?q=language:java&page=1&per_page=10"
        
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
            cell.registeredLabel.text = cellItems[indexPath.row].registered.description
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
            self.newRequest()
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(cellHeight)
    }
}

