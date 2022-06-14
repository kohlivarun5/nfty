//
//  AlchemyApi.swift
//  NFTY
//
//  Created by Varun Kohli on 6/13/22.
//

import Foundation
import PromiseKit
import Web3
import Cache

struct AlchemyApi {
  
  struct Impl {
    enum HTTPError: Error {
      case unknown
      case error(status: Int, message: String?)
    }
    
    static func fetch<Result:Decodable>(url: URL, params: [String: Any]?) -> Promise<Result> {
      
      var request = URLRequest(url: url)
      request.httpMethod = params.flatMap {_ in "POST"} ?? "GET"
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = params.flatMap { try? JSONSerialization.data(withJSONObject: $0, options: []) }
      return Promise.init { seal in
        print("Calling \(request.url!) with body = \(request.httpBody.map { String(decoding: $0,as:UTF8.self) } ?? "")")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
          
          if let error = error { return seal.reject(error) }
          // print(data)
          // print(String(decoding:data!,as:UTF8.self))
          switch(data.flatMap { try? JSONDecoder().decode(Result.self, from: $0) }) {
          case .some(let result):
            seal.fulfill(result)
          case .none:
            if let httpResponse = response as? HTTPURLResponse {
              let error = HTTPError.error(status: httpResponse.statusCode,
                                          message: data.flatMap({ String(data: $0, encoding: .utf8) }))
              seal.reject(error)
            } else {
              seal.reject(HTTPError.unknown)
            }
          }
        }
        task.resume()
      }
    }
  }
  
  struct GetNFTs {
    
    struct Result : Decodable {
      struct OwnedNFT : Decodable {
        struct Contract : Decodable {
          let address : String
        }
        struct Id : Decodable {
          let tokenId : String
        }
        let contract : Contract
        let id : Id
      }
      let ownedNfts : [OwnedNFT]
      let pageKey : String?
      let totalCount : UInt
    }
    
    static func get(owner:EthereumAddress,pageKey:String?) -> Promise<Result> {
      var components = URLComponents()
      // https://eth-mainnet.alchemyapi.io/v2/StghaadzMZpTbz5As9hHcmEMxl5Hcflc
      components.scheme = "https"
      components.host = "eth-mainnet.alchemyapi.io"
      components.path = "/v2/StghaadzMZpTbz5As9hHcmEMxl5Hcflc/getNFTs"
      components.queryItems = [
        URLQueryItem(name: "owner", value: owner.hex(eip55: true)),
        URLQueryItem(name: "withMetadata", value: String(false)),
        URLQueryItem(name: "filters[]", value: String("SPAM"))
      ]
      if let pageKey = pageKey {
        components.queryItems?.append(URLQueryItem(name: "pageKey", value: pageKey))
      }
      
      return AlchemyApi.Impl.fetch(url: components.url!, params: nil)
    }
  }
  
  struct GetFloor {
    
    struct Result : Decodable {
      struct FloorPrice : Decodable {
        let marketplace : String?
        let floorPrice : Double?
        let priceCurrency : String?
      }
      let floorPrices : [FloorPrice]
    }
    
    static func get(contractAddress:String) -> Promise<Result> {
      
      // curl 'https://eth-mainnet.g.alchemy.com/nft/v2/demo/getFloorPrice?contractAddress=0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d'
      
      var components = URLComponents()
      components.scheme = "https"
      components.host = "eth-mainnet.g.alchemy.com"
      components.path = "/nft/v2/StghaadzMZpTbz5As9hHcmEMxl5Hcflc/getFloorPrice"
      components.queryItems = [
        URLQueryItem(name: "contractAddress", value: contractAddress)
      ]
      return AlchemyApi.Impl.fetch(url: components.url!, params: nil)
    }
    
    static private var indicativeFloorCache = try! DiskStorage<String, Double>(
      config: DiskConfig(name: "AlchemyApi.GetFloor.indicativeFloor",expiry: .seconds(120)),
      transformer: TransformerFactory.forCodable(ofType: Double.self))
    
    static func indicativeFloor(_ contractAddress:String) -> Promise<PriceUnit?> {
      
      try? indicativeFloorCache.removeExpiredObjects()
      switch(try? indicativeFloorCache.object(forKey:contractAddress)) {
      case .some(let floor):
        return Promise.value(PriceUnit.wei(BigUInt(floor * 1e18)))
      case .none:
        return GetFloor.get(contractAddress: contractAddress)
          .map {
            $0.floorPrices.filter { $0.priceCurrency == "ETH" || $0.priceCurrency == "WETH" }
              .filter { $0.floorPrice != .none }
              .first
              .map {
                try! indicativeFloorCache.setObject($0.floorPrice!,forKey: contractAddress)
                return PriceUnit.wei(BigUInt($0.floorPrice! * 1e18))
              }
          }
      }
    }
  }
  
}
