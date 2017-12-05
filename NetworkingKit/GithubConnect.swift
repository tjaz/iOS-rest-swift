//
//  Connect.swift
//  NetworkingKit
//
//  Created by Tjaz Hrovat on 02/12/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import Foundation

public enum NetworkingError: Error {
    case noResponse(reason: String)
    case urlError(reason: String)
}

public class GithubConnect {
    
    struct ItemCodable: Codable {
        let url: String
    }
    
    struct BodyCodable: Codable {
        let total_count: Int
        let incomplete_results: Bool
        let items: [ItemCodable]
    }
    
    public static func getJavaDevelopers(page: Int, perPage: Int, userCallback: ((URL) throws -> Void)?, completionHandler: @escaping (Error?) -> Void) {
        let searchURL = "https://api.github.com/search/users?q=language:java+type:user&page=\(page)&per_page=\(perPage)"
        
        guard let url = URL(string: searchURL) else {
            completionHandler(nil)
            return
        }
        let session = URLSession.shared
        
        session.dataTask(with: url) { (data, response, error) in
            do {
                guard let response = response else {
                    throw NetworkingError.noResponse(reason: "No response from github api.")
                }
                print(response)
                
                guard let data = data else {
                    throw NetworkingError.noResponse(reason: "No response from github api.")
                }
                //let json = try JSONSerialization.jsonObject(with: data, options: [])
                //print(json)
                
                let decoder = JSONDecoder()
                let bodyDecoded = try decoder.decode(BodyCodable.self, from: data)
                
                for item in bodyDecoded.items {
                    guard let userURL = URL(string: item.url) else {
                        throw NetworkingError.urlError(reason: "Invalid url for user.")
                    }
                    try userCallback?(userURL)
                }
                
                completionHandler(nil)
            } catch {
                completionHandler(error)
            }
        }.resume()
    }
}
