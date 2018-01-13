//
//  Rest.swift
//  GithubConnectKit
//
//  Created by Tjaz Hrovat on 05/01/2018.
//  Copyright © 2018 Tjaz Hrovat. All rights reserved.
//

import Foundation

public enum NetworkingError: Error {
    case responseError(reason: String)
    case urlError(reason: String)
}

public class Rest {
    
    struct BodyCodable: Codable {
        let total_count: Int
        let incomplete_results: Int
        let items: [ItemCodable]
    }
    
    struct ItemCodable: Codable {
        let url: String
    }
    
    public static func getJavaDevelopers(page: Int, perPage: Int, userCallback: @escaping (URL)throws -> Void, completionHandler: @escaping (Error?)->Void) {
        guard let searchURL = URL(string: "https://api.github.com/search/users?q=language:java+type:user&page=\(page)&per_page=\(perPage)") else {
            return
        }
        
        let session = URLSession.shared
        
        session.dataTask(with: searchURL) { (data, response, error) in
            do {
            
                guard let response = response else {
                    throw NetworkingError.responseError(reason: "No header response from github api service.")
                }
                print(response)
                
                guard let data = data else {
                    throw NetworkingError.responseError(reason: "No body response from github api service.")
                }
                //let json = try JSONSerialization.jsonObject(with: data, options: [])
                //print(json)
                
                let decoder = JSONDecoder()
                let bodyDecoded = try decoder.decode(BodyCodable.self, from: data)
                
                for itemDecoded in bodyDecoded.items {
                    guard let userURL = URL(string: itemDecoded.url) else {
                        throw NetworkingError.urlError(reason: "Invalid user url.")
                    }
                    try userCallback(userURL)
                }
                
                completionHandler(nil)
            } catch {
                completionHandler(error)
            }
        }.resume()
    }
}
