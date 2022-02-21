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
            // print(data,response,error)
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
    token_id:String?) -> Promise<ActivitiesResult> {
      
      var params : [String : String] = [:]
      let _ = contract_id.map {
        params["contract_id"] = $0
      }
      
      let _ = token_id.map {
        params["token_id"] = $0
      }
      
      return Impl.fetch(path:"/activities", params: params)
    }
}


extension ParasApi.ActivitiesResult.Data.Result.Price {
  enum CodingKeys: String, CodingKey {
    case numberDecimal = "$numberDecimal"
  }
}
