//
//  ViewController.swift
//  iosTest
//
//  Created by Tjaz Hrovat on 02/11/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import UIKit

class RowItem : NSObject
{
    let login: String
    let avatar_img: UIImage
    let created_at: String
    
    required init(_ login: String, _ avatar: UIImage, _ created: String) {
        self.login = login
        self.avatar_img = avatar
        self.created_at = created
    }
}

enum DataError: Error {
    case invalidData(reason: String)
    case invalidURL(reason: String)
}

protocol TableDelegate {
    func populate(_ tableView: UITableView, items: [RowItem])
}

class ViewController: UIViewController {
    
    struct User: Codable
    {
        let login: String
        let avatar_url: String
        let created_at: String
    }

    struct Items: Codable {
        let total_count: Int
        let incomplete_results: Int
        let items: [Owner]?
    }
    
    struct Owner: Codable {
        let url: String
    }
    
    @IBOutlet weak var sideScrollView: UIScrollView!
    
    var isTableViewInitialized = false
    
    let itemsPerPage:Int = 10
    let pageIndex = 1
    
    var owners:[Owner]?
    
    var urlNextPage: String?
    var pageLast: String?
    
    var slide: Slide!
    
    let urlUsers = "https://api.github.com/search/users"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        print(self.view.frame.size.width)
        
        self.slide = Bundle.main.loadNibNamed("Slide", owner: self, options: nil)?.first as! Slide
        
        slide.tableView.delegate = slide.tableView
        slide.tableView.dataSource = slide.tableView
     
        
        self.urlNextPage = urlUsers + "?q=language:java&order=desc&page=\(pageIndex)&per_page=\(itemsPerPage)"
        requestPages()
    }
    
    func requestPages()
    {
        guard let url = self.urlNextPage else {
            return
        }
        guard let reqUrl = URL(string: url) else {
            return
        }
        let session = URLSession.shared
        
        // get user data from the github api
        session.dataTask(with: reqUrl) { (data, response, error) -> Void in
            if let httpResponse = response as? HTTPURLResponse
            {
                print(httpResponse)
                
                if let link = httpResponse.allHeaderFields["Link"] as? String {
                    self.urlNextPage = self.linkUrl(direction: "next", link: link)
                }
            }
            guard let responseData = data else
            {
                return
            }
            
            let decoder = JSONDecoder()
            
            do {
                let items = try decoder.decode(Items.self, from: responseData)
                
                
                if items.total_count > 0
                {
                    guard let owners = items.items else
                    {
                        return
                    }
                    
                    var items: [RowItem] = [RowItem]()
                    for owner in owners
                    {
                        guard let userUrl = URL(string: owner.url) else {
                            throw DataError.invalidData(reason: "invalid url for user")
                        }
                        
                        guard let userData = NSData(contentsOf: userUrl) as Data? else {
                            throw DataError.invalidData(reason: "missing data for the user")
                        }
                        
                        let user = try decoder.decode(User.self, from: userData)
                        
                        guard let imgUrl = URL(string: user.avatar_url ) else {
                            throw DataError.invalidURL(reason: "invalid url")
                        }
                        
                        guard let imgData = NSData(contentsOf: imgUrl) as Data? else {
                            throw DataError.invalidData(reason: "missing data")
                        }
                        
                        let item: RowItem = RowItem(user.login, UIImage(data: imgData)!, user.created_at)
                        
                        print(item.login)
                        print(user.avatar_url)
                        print(item.created_at)
                        
                        items.append(item)
                        
                    }
                    // populate tables
                    self.performSelector(onMainThread: #selector(self.pushItems(items: )), with: items, waitUntilDone: false)

                }
                else
                {
                    return
                }
                
            } catch {
                print(error)
                //                completionHandler(nil, error)
            }
            
            }.resume()
    }
    
    @objc public func pushItems(items: [RowItem])
    {
        if !self.isTableViewInitialized
        {
            //self.setupSideScrollView(slides: self.slides)
            self.slide.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: self.view.frame.height)
            self.view.addSubview(slide)
            
            self.isTableViewInitialized = true
        }
        self.slide.tableView.populate(self.slide.tableView, items: items)
    }

//    func setupSideScrollView(slides: [Slide])
//    {
//        sideScrollView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
//        sideScrollView.contentSize = CGSize(width: view.frame.width * CGFloat(slides.count), height: view.frame.height)
//
//        for i in 0 ..< slides.count
//        {
//            slides[i].frame = CGRect(x: view.frame.width * CGFloat(i), y: 0, width: view.frame.width, height: view.frame.height)
//            sideScrollView.addSubview(slides[i])
//        }
//    }
    
    func linkUrl(direction: String, link: String) -> String?
    {
        let relDelimiter = "rel=\"\(direction)\","
        let relResult = link.components(separatedBy: relDelimiter)
        
        if relResult.count < 2 {
            return nil
        }
        
        var closing = relResult[1].components(separatedBy: ">")
        if closing.count < 2 {
            return nil
        }
        //let beginning = nextResult[..<closingIndex]
        var beginning = closing[0].components(separatedBy: "<")
        if beginning.count < 2 {
            return nil
        }
        let url = beginning[1]
        return url
    }
}

