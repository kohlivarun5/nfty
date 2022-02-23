//
//  ParasApi.swift
//  NFTY
//
//  Created by Varun Kohli on 2/20/22.
//

import Foundation
import PromiseKit

struct ParasApi {
  
  
  struct Impl {
    enum HTTPError: Error {
      case unknown
      case error(status: Int, message: String?)
    }
    
    static func fetch<Result:Decodable>(path: String, params: [String: String]) -> Promise<Result> {
      
      var components = URLComponents()
      components.scheme = "https"
      components.host = "api-v2-mainnet.paras.id"
      components.path = path
      components.queryItems = params.map { (key,value) in
        URLQueryItem(name: key,value:value)
      }
      
      var request = URLRequest(url:components.url!)
      request.httpMethod = "GET"
      
      return Promise.init { seal in
        print("Calling \(request.url!)")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
          if let error = error { return seal.reject(error) }
          
          do {
            switch(data) {
            case .some(let data):
              seal.fulfill(try JSONDecoder().decode(Result.self, from: data))
            case .none:
              // print(data,response,error)
              seal.reject(error ?? NSError(domain:"", code:404, userInfo:nil))
            }
          } catch {
            data.map { print(String(decoding:$0,as:UTF8.self)) }
            seal.reject(error)
          }
        }
        task.resume()
      }
    }
  }
  
  /*
   https://parashq.github.io/#req_8e9af92aea344879a51546833509e1c4
   
   curl "https://api-v2-mainnet.paras.id/activities?_id=61b48e6cc8c3dce0815c853a" \
   -X GET
   
   {
   "status": 1,
   "data": {
   "results": [
   {
   "_id": "61b48e6cc8c3dce0815c853a",
   "contract_id": "x.paras.near",
   "type": "nft_transfer",
   "from": "asepnurdinn.near",
   "to": "dannyock.near",
   "token_id": "8780:10",
   "token_series_id": "8780",
   "price": {
   "$numberDecimal": "300000000000000000000000"
   },
   "issued_at": 1639222888911,
   "msg": {
   "contract_id": "x.paras.near",
   "block_height": 54877559,
   "datetime": "2021-12-11T11:41:28.911609492+00:00",
   "event_type": "nft_transfer",
   "params": {
   "price": "300000000000000000000000",
   "receiver_id": "dannyock.near",
   "sender_id": "",
   "token_id": "8780:10"
   }
   },
   "creator_id": "asepnurdinn.near",
   "is_creator": true
   }
   ],
   "skip": 0,
   "limit": 10
   }
   }
   */
  
  struct ActivitiesResult : Decodable {
    struct Data : Decodable {
      struct Result : Decodable {
        let _id : String
        let contract_id : String
        let type : String
        let from : String?
        let to : String?
        let token_id : String
        
        struct Price : Decodable {
          let numberDecimal : String
        }
        
        let price : Price?
        
        struct Msg : Decodable {
          
          let contract_id : String
          let block_height : UInt
          let datetime : String
          let event_type : String
          
          /*
           struct Params : Decodable {
           let price : String
           let receiver_id : String
           let token_id : String
           }
           let params : Params
           */
          
        }
        let msg : Msg
      }
      let results : [Result]
    }
    let status:Int
    let data : Data
  }
  
  static func activities(
    contract_id:String?,
    token_id:String?,
    eventType:TradeEventType?,
    offset:UInt?,
    limit:UInt?) -> Promise<ActivitiesResult>
  {
    
    var params : [String : String] = [:]
    let _ = contract_id.map {
      params["contract_id"] = $0
    }
    
    let _ = token_id.map {
      params["token_id"] = $0
    }
    
    let _ = eventType.map {
      switch($0) {
      case .ask:
        params["type"] = "add_market_data"
      case .bid:
        params["type"] = "add_offer"
      case .bought:
        params["type"] = "resolve_purchase"
      case .transfer:
        params["type"] = "nft_transfer"
      case .minted:
        return // TODO : Find minted event
      }
    }
    
    let _ = offset.map {
      params["__skip"] = String($0)
    }
    
    let _ = limit.map {
      params["__limit"] = String($0)
    }
    
    return Impl.fetch(path:"/activities", params: params)
  }
  
  static public func eventType(_ type:String) -> TradeEventType? {
    switch(type) {
    case "nft_transfer":
      return TradeEventType.transfer
    case "resolve_purchase":
      return TradeEventType.bought
    case "add_offer":
      return TradeEventType.bid
    case "add_market_data":
      return TradeEventType.ask
    default:
      return nil
    }
  }
  
  enum Sort {
    case lowest_price
  }
  
  struct TokenSeriesResult : Codable {
    struct Data : Codable {
      struct Result : Codable {
        let contract_id : String
        let token_series_id : String
        let lowest_price : String
      }
      let results : [Result]
    }
    let status : UInt
    let data : Data
  }
  
  // https://api-v2-mainnet.paras.id/token-series?collection_id=asac.near&exclude_total_burn=true&__limit=8&__sort=lowest_price::1&lookup_token=true
  static func token_series(
    collection_id:String,
    offset:UInt?,
    limit:UInt?,
    sort:Sort?) -> Promise<TokenSeriesResult>
  {
    
    var params : [String : String] = [:]
    params["contract_id"] = collection_id
       
    let _ = offset.map {
      params["__skip"] = String($0)
    }
    
    let _ = limit.map {
      params["__limit"] = String($0)
    }
    
    let _ = sort.map {
      switch($0) {
      case .lowest_price:
        params["__sort"] = "lowest_price::1"
      }
    }
    
    return Impl.fetch(path:"/token-series", params: params)
  }
  
  struct CollectionStats : Codable {
    struct Data : Codable {
      struct Result : Codable {
        let floor_price : String
      }
      let results : [Result]
    }
    let status : UInt
    let data : Data
  }
  
  // https://api-v2-mainnet.paras.id/collection-stats
  static func token_series(
    collection_id:String) -> Promise<CollectionStats>
  {
    
    var params : [String : String] = [:]
    params["contract_id"] = collection_id
    
    return Impl.fetch(path:"/collection-stats", params: params)
  }
  
  
}


extension ParasApi.ActivitiesResult.Data.Result.Price {
  enum CodingKeys: String, CodingKey {
    case numberDecimal = "$numberDecimal"
  }
}
