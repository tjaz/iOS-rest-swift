//
//  Networking.swift
//  NetworkKit
//
//  Created by Tjaz Hrovat on 24/11/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import UIKit

struct ResponseBodyDecodable : Codable{
    let total_count: Int
    let incomplete_results: Bool
    let items: [ItemDecodable]
}

public struct UserURL {
    public let url: String
}

struct ItemDecodable : Codable {
    let url: String
}

public class Networking: NSObject {
    
    enum BackendError: Error {
        case noResponse(reason:String)
    }
    
    static let searchUsersURL = "https://api.github.com/search/users"
    
    
    open static func requestUserItems(page: Int, perPage: Int, completionHeader: @escaping ( [UserURL]?, Error?) -> Void ) {
               
        guard let url = URL(string: searchUsersURL + "?q=language:java&page=\(page)&per_page=\(perPage)") else {
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
                    
                    var urls: [UserURL] = [UserURL]()
                    
                    for item in body.items {
                        urls.append( UserURL(url: item.url) )
                    }
                    
                    completionHeader(urls, nil)
                } catch {
                    completionHeader(nil, error)
                }
            }
        }.resume()
    }
    
}
