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
          
          if let httpResponse = response as? HTTPURLResponse {
            // https://docs.alchemy.com/alchemy/documentation/throughput#http
            guard (httpResponse.statusCode != 429) else {
              // Retry
              // print("Retry header=\(httpResponse.value(forHTTPHeaderField:"retry-after")) in url =\(httpResponse))")
              let retry_ms = httpResponse.value(forHTTPHeaderField:"retry-after").flatMap { Double($0) } ?? 1150
              let random_retry_ms = Double.random(in:retry_ms-100 ... retry_ms+100)
              print("Scheduling rety after \(random_retry_ms)ms")
              DispatchQueue.global(qos:.userInitiated).asyncAfter(deadline: .now()+(random_retry_ms / 1000.0)) {
                fetch(url:url,params:params)
                  .done { seal.fulfill($0) }.catch { seal.reject($0)}
              }
              return
            }
          }
          
          if let error = error { return seal.reject(error) }
          // print(data)
          // print(String(decoding:data!,as:UTF8.self))
          
          guard let data = data else {
            let error = HTTPError.error(status: 500,message: "Data is empty")
            seal.reject(error)
            return
          }
          
          do {
            seal.fulfill(try JSONDecoder().decode(Result.self, from: data))
          } catch {
            print("JSON Serialization error:\(error), json=\(String(decoding: data, as: UTF8.self))")
            seal.reject(error)
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
      
      typealias FloorPrices = [String:FloorPrice]
    }
    
    static func get(contractAddress:String) -> Promise<Result.FloorPrices> {
      
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
      
      return Promise { seal in
        
        DispatchQueue.global(qos: .userInteractive).async {
          try? indicativeFloorCache.removeExpiredObjects()
          switch(try? indicativeFloorCache.object(forKey:contractAddress)) {
          case .some(let floor):
            seal.fulfill(PriceUnit.wei(BigUInt(floor * 1e18)))
          case .none:
            GetFloor.get(contractAddress: contractAddress)
              .map(on:.global(qos: .userInteractive)) {
                $0.values.filter { $0.priceCurrency == "ETH" || $0.priceCurrency == "WETH" }
                  .filter { $0.floorPrice != .none }
                  .sorted { $0.floorPrice! < $1.floorPrice! }
                  .first
                  .map {
                    try? indicativeFloorCache.setObject($0.floorPrice!,forKey: contractAddress)
                    return PriceUnit.wei(BigUInt($0.floorPrice! * 1e18))
                  }
              }
              .done(on:.global(qos: .userInteractive)) { seal.fulfill($0) }
              .catch { seal.reject($0) }
          }
        }
      }
    }
  }
  
  struct GetNFTMetaData {
    
    // Result(contract: DownloadCollection.AlchemyApi.GetNFTMetaData.Result.Contract(address: "0x1a2f71468f656e97c2f86541e57189f59951efe7"), id: DownloadCollection.AlchemyApi.GetNFTMetaData.Result.Id(tokenId: "5067"), media: [DownloadCollection.AlchemyApi.GetNFTMetaData.Result.Media(raw: "https://ipfs.io/ipfs/QmSnoLjp5nyG7w26KPM3XaPUsB6VfrFVTAkMZ2vwTFZebE", gateway: "https://res.cloudinary.com/alchemyapi/image/upload/mainnet/34ddeba4023299a30017b4ff9f4eb857.jpg", thumbnail: Optional("https://res.cloudinary.com/alchemyapi/image/upload/w_256,h_256/mainnet/34ddeba4023299a30017b4ff9f4eb857.jpg"))], metadata: DownloadCollection.AlchemyApi.GetNFTMetaData.Result.Metadata(image: "https://ipfs.io/ipfs/QmSnoLjp5nyG7w26KPM3XaPUsB6VfrFVTAkMZ2vwTFZebE", external_url: nil))
    struct Result : Decodable {
      struct Contract : Decodable {
        let address : String
      }
      struct Id : Decodable {
        let tokenId : String
      }
      struct Media : Decodable {
        let raw : String
        let gateway : String
        let thumbnail : String?
      }
      struct Metadata : Decodable {
        let image : String?
        let external_url : String?
        let animation_url : String?
        let image_data : String?
      }
      let contract : Contract
      let id : Id
      let media : [Media]
      let metadata : Metadata
    }
    
    enum TokenType : String {
      case ERC721
      case ERC1155
    }
    
    static func get(contractAddress:EthereumAddress,tokenId:BigUInt,tokenType:TokenType) -> Promise<Result> {
      var components = URLComponents()
      // https://eth-mainnet.alchemyapi.io/v2/StghaadzMZpTbz5As9hHcmEMxl5Hcflc
      components.scheme = "https"
      components.host = "eth-mainnet.alchemyapi.io"
      components.path = "/v2/StghaadzMZpTbz5As9hHcmEMxl5Hcflc/getNFTMetadata"
      components.queryItems = [
        URLQueryItem(name: "contractAddress", value: contractAddress.hex(eip55: true)),
        URLQueryItem(name: "tokenId", value: String(tokenId)),
        URLQueryItem(name: "tokenType", value: tokenType.rawValue)
      ]
      
      return AlchemyApi.Impl.fetch(url: components.url!, params: nil)
    }
  }
  
}
