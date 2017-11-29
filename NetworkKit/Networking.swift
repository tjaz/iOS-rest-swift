//
//  Networking.swift
//  NetworkKit
//
//  Created by Tjaz Hrovat on 25/11/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import UIKit

public enum BackendError: Error {
    case responseError(reason: String)
    case urlError(reason: String)
}

public struct UserItem {
    public let url: URL
}

public class Networking: NSObject {
    
    struct ItemCodable: Codable {
        let url: String
    }
    
    struct BodyCodable: Codable {
        let total_count: Int
        let incomplete_results: Bool
        let items: [ItemCodable]
    }
    
    static let searchUsersLink = "https://api.github.com/search/users?q=language:java+type:user"
    
    public static func requestJavaDevelopers(page: Int, perPage: Int, returnUser: @escaping (UserItem) throws -> Void, completionHandler: @escaping (Error?) -> Void) {
        guard let url = URL(string: self.searchUsersLink + "&page=\(page)&per_page=\(perPage)") else {
            return
        }
        let session = URLSession.shared
        
        session.dataTask(with: url) { (data, response, error) in
            do {
                
                if let response = response {
                    print(response)
                }
                
                guard let data = data else {
                    //print(data)
                    throw BackendError.responseError(reason: "no data in response body.")
                }
                
                //let json = try JSONSerialization.jsonObject(with: data, options: [])
                //print(json)
                
                let decoder = JSONDecoder()
                
                let bodyCodable = try decoder.decode(BodyCodable.self, from: data)
                
                for item in bodyCodable.items {
                    guard let userURL = URL(string: item.url) else {
                        throw BackendError.urlError(reason: "invalid URL for user.")
                    }
                    try returnUser(UserItem(url: userURL))
                }
                
                completionHandler(nil)
            } catch {
                completionHandler(error)
            }
        }.resume()
    }
}
