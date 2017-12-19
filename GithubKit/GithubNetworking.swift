//
//  Networking.swift
//  GithubKit
//
//  Created by Tjaz Hrovat on 14/12/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import Foundation

public enum NetworkingError: Error {
    case noResponse(reason: String)
    case invalidUrl(reason: String)
}

public class GithubNetworking: NSObject {
    
    class BodyCodable: Codable {
        let total_count: UInt32
        let incomplete_results: Bool
        let items: [ItemCodable]
    }
    
    class ItemCodable: Codable {
        let url: String
    }
    
    public static func getUsers(page: Int, perPage: Int, userCallback:@escaping (URL) throws -> Void, completionHandler: @escaping (Error?) -> Void) {
        guard let searchUsersURL = URL(string: "https://api.github.com/search/users?q=language:java+type:user&page=\(page)&per_page=\(perPage)") else {
            return
        }
        let session = URLSession.shared
        session.dataTask(with: searchUsersURL) { (data, response, error) in
            do {
                guard let response = response else {
                    throw NetworkingError.noResponse(reason: "No header response from github api service.")
                }
                print(response)
                
                guard let data = data else {
                    throw NetworkingError.noResponse(reason: "No body response from github api service.")
                }
                
                let decoder = JSONDecoder()
                let bodyDecoded = try decoder.decode(BodyCodable.self, from: data)
                
                for item in bodyDecoded.items {
                    guard let userURL = URL(string: item.url) else {
                        throw NetworkingError.invalidUrl(reason: "Invalid url for user.")
                    }
                    try userCallback(userURL)
                }
                
                completionHandler(nil)
            } catch {
                completionHandler(error)
                return
            }
            
        }.resume()
    }
    
}
