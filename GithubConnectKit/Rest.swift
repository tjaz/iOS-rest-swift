//
//  Rest.swift
//  GithubConnectKit
//
//  Created by Tjaz Hrovat on 26/12/2017.
//  Copyright © 2017 Tjaz Hrovat. All rights reserved.
//

import Foundation

public enum NetworkingError: Error {
    case urlError(reason: String)
    case responseError(reason: String)
}

public class Rest: NSObject {
    
    struct BodyCodable: Codable {
        var total_count: Int
        var incomplete_results: Bool
        var items: [ItemCodable]
    }
    
    struct ItemCodable: Codable {
        var url: String
    }
    
    public static func getJavaDevelopers(page:Int, perPage:Int, userCallback: @escaping (URL) throws ->Void, completionHandler:@escaping (Error?) ->Void) {
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
                
                guard let bodyData = data else {
                    throw NetworkingError.responseError(reason: "No body response from github api service.")
                }
                
                let decoder = JSONDecoder()
                let bodyCodable = try decoder.decode(BodyCodable.self, from: bodyData)
                for item in bodyCodable.items {
                    guard let userURL = URL(string: item.url) else {
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
