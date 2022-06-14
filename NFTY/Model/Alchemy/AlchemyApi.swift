//
//  AlchemyApi.swift
//  NFTY
//
//  Created by Varun Kohli on 6/13/22.
//

import Foundation
import PromiseKit
import Web3


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
          print(String(decoding:data!,as:UTF8.self))
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
}
