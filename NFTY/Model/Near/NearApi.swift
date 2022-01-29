//
//  NearApi.swift
//  NFTY
//
//  Created by Varun Kohli on 1/26/22.
//

import Foundation
import PromiseKit

struct NearApi {
  
  
  struct Impl {
    enum HTTPError: Error {
      case unknown
      case error(status: Int, message: String?)
    }
    
    struct RpcResponse<Result:Decodable> : Decodable {
      let result : Result
    }
    
    static func fetch<Result:Decodable>(url: URL, params: [String: Any]?) -> Promise<Result> {
      
      let session = URLSession.shared
      var request = URLRequest(url: url)
      request.httpMethod = params.flatMap {_ in "POST"} ?? "GET"
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = params.flatMap { try? JSONSerialization.data(withJSONObject: $0, options: []) }
      return Promise.init { seal in
        let task = session.dataTask(with: request) { data, response, error in
          if let error = error { return seal.reject(error) }
          // print(data)
          // print(String(decoding:data!,as:UTF8.self))
          switch(data.flatMap { try? JSONDecoder().decode(RpcResponse<Result>.self, from: $0) }?.result ) {
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
  
  /*
   https://docs.near.org/docs/api/rpc/contracts#call-a-contract-function
   {
   "jsonrpc": "2.0",
   "id": "dontcare",
   "method": "query",
   "params": {
   "request_type": "call_function",
   "finality": "final",
   "account_id": "dev-1588039999690",
   "method_name": "get_num",
   "args_base64": "e30="
   }
   }
   */
  
  public struct QueryResult: Equatable, Decodable {
    let logs: [String]
    let result: [UInt8]
  }
  
  static func call_function<
    INPUT:Encodable,
    OUTPUT: Decodable>(
      account_id:String,
      method_name:String,
      args: INPUT) -> Promise<OUTPUT> {
        
        let request: [String: Any] = [
          "jsonrpc": "2.0",
          "id": "dontcare",
          "method": "query",
          "params": [
            "request_type": "call_function",
            "finality": "final",
            "account_id": account_id,
            "method_name": method_name,
            "args_base64": try! JSONEncoder().encode(args).base64EncodedString()
          ]
        ]
        return Impl.fetch(url:URL(string:"https://rpc.mainnet.near.org")!, params: request)
          .map { (result:QueryResult) in
            print(result.logs)
            print(String(data:Data(result.result),encoding:.ascii) as Any)
            return try JSONDecoder().decode(OUTPUT.self, from: Data(result.result))
          }
      }
  
  /*
   {
   "jsonrpc": "2.0",
   "id": "dontcare",
   "method": "EXPERIMENTAL_changes",
   "params": {
   "changes_type": "account_changes",
   "account_ids": ["your_account.testnet"],
   "block_id": 19703467
   }
   }
   */
  
  struct AccountChanges : Decodable {
    /*
     {
     "block_hash": "6U8Yd4JFZwJUNfqkD4KaKgTKmpNSmVRTSggpjmsRWdKY",
     "changes": [
     {
     "cause": {
     "type": "receipt_processing",
     "receipt_hash": "9ewznXgs2t7vRCssxW4thgaiwggnMagKybZ7ryLNTT2z"
     },
     "type": "data_update",
     "change": {
     "account_id": "guest-book.testnet",
     "key_base64": "bTo6Mzk=",
     "value_base64": "eyJwcmVtaXVtIjpmYWxzZSwic2VuZGVyIjoiZmhyLnRlc3RuZXQiLCJ0ZXh0IjoiSGkifQ=="
     }
     },
     {
     "cause": {
     "type": "receipt_processing",
     "receipt_hash": "9ewznXgs2t7vRCssxW4thgaiwggnMagKybZ7ryLNTT2z"
     },
     "type": "data_update",
     "change": {
     "account_id": "guest-book.testnet",
     "key_base64": "bTpsZW4=",
     "value_base64": "NDA="
     }
     }
     ]
     }
     */
    
    let block_hash : String
  }
  
  static func changes(account_ids:[String]) -> Promise<AccountChanges> {
    
    let request: [String: Any] = [
      "jsonrpc": "2.0",
      "id": "dontcare",
      "method": "EXPERIMENTAL_changes",
      "params": [
        "changes_type": "account_changes",
        "account_ids": account_ids,
        "finality" : "final"
      ]
    ]
    return Impl.fetch(url:URL(string:"https://rpc.mainnet.near.org")!, params: request)
      .map { (result:AccountChanges) in
        print(result)
        return result
      }
    
  }
}
