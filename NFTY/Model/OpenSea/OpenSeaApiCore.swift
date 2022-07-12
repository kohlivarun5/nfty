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
  
  static let UrlSession = UrlTaskThrottle(
    queue:DispatchQueue(label: "OpenSeaApiCore.serialQueue",qos:.userInitiated),
    deadline:DispatchTimeInterval.milliseconds(500),
    timeoutIntervalForRequest:3.0,
    timeoutIntervalForResource:10.0)
  
  struct CollectionInfo : Codable {
    let name : String
    let image_url : URL?
    let slug : String?
    let external_url : URL?
  }
  
  static private var collectionCache = try! DiskStorage<String, CollectionInfo?>(
    config: DiskConfig(name: "OpenSeaApi/api/v1/asset_contract",expiry: .never),
    transformer: TransformerFactory.forCodable(ofType: CollectionInfo?.self))
  
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
        // request.setValue(OpenSeaApiCore.API_KEY, forHTTPHeaderField:"x-api-key")
        
        request.httpMethod = "GET"
        
        OpenSeaApiCore.UrlSession.enqueue(with: request, completionHandler: { data, response, error -> Void in
          if let e = error { return seal.reject(e) }
          do {
            let jsonDecoder = JSONDecoder()
            // print(data)
            struct Data : Codable {
              let collection : CollectionInfo?
              let schema_name : String?
            }
            
            let info = try jsonDecoder.decode(Data.self, from: data!)
            if (info.schema_name != "ERC721" || info.collection == nil) {
              try collectionCache.setObject(CollectionInfo?.none,forKey: contract)
              seal.reject(NSError(domain:"", code:404, userInfo:nil))
            } else {
              try collectionCache.setObject(info.collection,forKey: contract)
              seal.fulfill(info.collection!)
            }
            
          } catch {
            print("JSON Serialization error:\(error), json=\(data.map { String(decoding: $0, as: UTF8.self) } ?? "")")
            seal.reject(NSError(domain:"", code:404, userInfo:nil))
          }
        })
      }
    }
  }
}
