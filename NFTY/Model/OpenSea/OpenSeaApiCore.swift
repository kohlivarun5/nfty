//
//  OpenSeaApiCore.swift
//  NFTY
//
//  Created by Varun Kohli on 2/6/22.
//

import Foundation
import PromiseKit
import Cache

struct OpenSeaApiCore {
  
  static let API_KEY = "5302eafecee44b198cfa1fb8bfbd5e5d"
  
  struct CollectionInfo : Codable {
    let name : String
    let image_url : URL?
    let slug : String?
    let external_url : URL?
  }
  
  static private var collectionCache = try! DiskStorage<String, CollectionInfo>(
    config: DiskConfig(name: "OpenSeaApi/api/v1/asset_contract",expiry: .never),
    transformer: TransformerFactory.forCodable(ofType: CollectionInfo.self))
  
  static func getCollectionInfo(contract:String) -> Promise<CollectionInfo> {
    return Promise { seal in
      
      switch(try? collectionCache.object(forKey: contract)) {
      case .some(let info):
        seal.fulfill(info)
      case .none:
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.opensea.io"
        components.path = "/api/v1/asset_contract/\(contract)"
        
        var request = URLRequest(url:components.url!)
        request.setValue(OpenSeaApiCore.API_KEY, forHTTPHeaderField:"x-api-key")
        
        request.httpMethod = "GET"
        
        print("calling \(request.url!)")
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
          if let e = error { return seal.reject(e) }
          do {
            let jsonDecoder = JSONDecoder()
            // print(data)
            struct Data : Codable {
              let collection : CollectionInfo
            }
            
            let info = try jsonDecoder.decode(Data.self, from: data!).collection
            try collectionCache.setObject(info,forKey: contract)
            
            seal.fulfill(info)
          } catch {
            print("JSON Serialization error:\(error), json=\(data.map { String(decoding: $0, as: UTF8.self) } ?? "")")
            seal.reject(NSError(domain:"", code:404, userInfo:nil))
          }
        }).resume()
      }
    }
  }
}
