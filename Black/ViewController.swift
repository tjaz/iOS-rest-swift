//
//  ViewController.swift
//  Black
//
//  Created by Tjaz Hrovat on 17/11/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import UIKit

enum BackendError: Error {
    case urlError(reason: String)
    case noResponse(reason: String)
    case objectSerialization(reason: String)
}

struct DetailedUser {
    let avatar: UIImage
    let type: String
    let name: String // ?
    let company: String // ?
    let location: String // ?
    let email: String // ?
    let followers: Int
    let isPhone: Bool
}

class TableViewController: UITableViewController {
    
    enum UserInterfaceIdom {
        case unspecified
        
        case phone  // iPhone style UI
        case pad    // iPad style UI
    }
    
    struct User {
        let url: URL
        let username: String
        let avatar: UIImage
        let registrationDate: Date
    }
    
    struct DetailedUserDecodable: Codable {
        let type: String?
        let name: String?
        let company: String?
        let location: String?
        let email: String?
        let followers: Int
    }
    
    struct ResponseBodyDecodable : Codable{
        let total_count: Int
        let incomplete_results: Bool
        let items: [ItemDecodable]
    }
    
    struct ItemDecodable : Codable {
        let url: String
    }
    
    struct UserDecodable : Codable {
        let login: String
        let avatar_url: String
        let created_at: String
    }
   
    let searchUsersURL = "https://api.github.com/search/users"
    
    var page = 0
    var perPage = 10
    
    var userCells :[User] = [User]()
    
    let cellRowHeight = 100.0
    
    var lockScrollEnd = false
    var lastContentHeight: CGFloat = 0.0
    
    func parseJSON(completionHeader: @escaping ( [User]?, Error?) ->Void) {
        guard let url = URL(string: searchUsersURL + "?q=language:java&page=\((page+1)*perPage)&per_page=\(perPage)") else {
            return
        }
        
        let session: URLSession = URLSession(configuration: URLSessionConfiguration.ephemeral, delegate: nil, delegateQueue: OperationQueue.current)
        session.dataTask(with: url) { (data, response, error) in
            if let httpResponse = response {
                print(httpResponse)
            } else {
                completionHeader(nil, BackendError.noResponse(reason: "header is null"))
            }            
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    print(json)
                    
                    let decoder = JSONDecoder()
                    let body = try decoder.decode(ResponseBodyDecodable.self, from: data)
                    
                    var users :[User] = [User]()
                    for item in body.items {
                        guard let userURL = URL(string: item.url) else {
                            completionHeader(nil, BackendError.urlError(reason: "unable to parse user url."))
                            return
                        }
                        
                        let userData = try Data(contentsOf: userURL)
                        let userDecodable = try decoder.decode(UserDecodable.self, from: userData)
                        
                        // registered
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                        let regDate = dateFormatter.date(from: userDecodable.created_at)!
                        
                        // avatar
                        guard let avatarURL = URL(string: userDecodable.avatar_url) else {
                            completionHeader(nil, BackendError.urlError(reason: "unable to parse avatar url."))
                            return
                        }
                        let avatarData = try Data(contentsOf: avatarURL)
                        guard let avatar = UIImage(data: avatarData) else {
                            completionHeader(nil, BackendError.objectSerialization(reason: "unable to create image."))
                            return
                        }
                        print(userDecodable.login)
                        print(userDecodable.created_at)
                        
                        users.append( User(url: userURL, username: userDecodable.login, avatar: avatar, registrationDate: regDate) )
                    }
                    
                    completionHeader(users, nil)
                } catch {
                    completionHeader(nil, error)
                }
            } else {
                completionHeader(nil, BackendError.noResponse(reason: "body is null"))
            }
        }.resume()
    }
    
    func getJavaUsers(completionHandler: (() -> Void)?) {
        parseJSON { (users, error) in
            self.lockScrollEnd = false
            self.lastContentHeight = self.tableView.contentSize.height
            
            if let error = error {
                print(error)
                return
            }
            if users != nil {
                self.userCells += users!
                self.page += 1
                if completionHandler != nil {
                    completionHandler!()
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    @objc func performOnMainThread(loadController: UIViewController) {
        self.present(loadController, animated: true, completion: {
            print("loading screen should be presented by now.")
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
      
        let loadController = Bundle.main.loadNibNamed("LoadViewController", owner: self, options: nil)?.first as! UIViewController
        
        //self.present(loadController, animated: true)
        
        self.performSelector(onMainThread:#selector(self.performOnMainThread), with: loadController, waitUntilDone: false)

        
        getJavaUsers(completionHandler: {
            self.dismiss(animated: true, completion: nil)
            self.tableView.reloadData()
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! MainTableViewCell
        
        cell.avatarImage.image = userCells[indexPath.row].avatar
        
        let date = userCells[indexPath.row].registrationDate
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let months = ["January", "February", "March", "April", "May", "June", "Jully", "August", "September", "October", "November", "December"]
        cell.registratedLabel.text = "\(day) \(months[month-1]) \(year)"
        
        cell.usernameLabel.text = userCells[indexPath.row].username
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userCells.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(self.cellRowHeight)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
                
        if ( lockScrollEnd || self.lastContentHeight >= self.tableView.contentSize.height ||  scrollView.contentOffset.y < 0) {
            return
        }
        
        if (self.tableView.contentOffset.y >= (self.tableView.contentSize.height - self.tableView.bounds.height)) {
            self.lockScrollEnd = true
            
            DispatchQueue.main.async{
                self.getJavaUsers(completionHandler: {
                    self.tableView.reloadData()
                })
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let userCell = userCells[indexPath.row]
        do {
            let userData = try Data(contentsOf: userCell.url)
            let decoder = JSONDecoder()
            let userDecoded = try decoder.decode(DetailedUserDecodable.self, from: userData)
            
            let name: String!
            if userDecoded.name != nil {
                name = userDecoded.name
            } else {
                name = ""
            }
            
            let company: String!
            if userDecoded.company != nil {
                company = userDecoded.company
            } else {
                company = ""
            }
            
            let location: String!
            if userDecoded.location != nil {
                location = userDecoded.location
            } else {
                location = ""
            }
            
            let email: String!
            if userDecoded.email != nil {
                email = userDecoded.email
            } else {
                email = "test@test.com"
            }
            
            let isPhone: Bool!
            if UIDevice.current.userInterfaceIdiom == .phone {
                isPhone = true
            } else {
                isPhone = false
            }
            
            let user = DetailedUser(avatar: userCell.avatar, type: userDecoded.type!, name: name, company: company, location: location, email: email, followers: userDecoded.followers, isPhone: isPhone)
            
            let userViewController = Bundle.main.loadNibNamed("UserViewController", owner: self, options: nil)?.first as! UserViewController
            
            userViewController.setUserInformation(user: user)
            
            self.navigationController!.pushViewController(userViewController, animated: true)
            
        } catch {
            print(error)
        }
        
    }
    
}

