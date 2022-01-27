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
    
    public struct QueryResult: Equatable, Decodable {
      let logs: [String]
      let result: [UInt8]
    }
    
    struct RpcResponse :Decodable {
      /*
      {
        "jsonrpc": "2.0",
        "result": {
          "result": [48],
          "logs": [],
          "block_height": 17817336,
          "block_hash": "4qkA4sUUG8opjH5Q9bL5mWJTnfR4ech879Db1BZXbx6P"
        },
        "id": "dontcare"
      }
       */
      let result : QueryResult
    }
    
    static func fetch(url: URL, params: [String: Any]?) -> Promise<QueryResult> {
      
      let session = URLSession.shared
      var request = URLRequest(url: url)
      request.httpMethod = params.flatMap {_ in "POST"} ?? "GET"
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = params.flatMap { try? JSONSerialization.data(withJSONObject: $0, options: []) }
      return Promise.init { seal in
        let task = session.dataTask(with: request) { data, response, error in
          if let error = error { return seal.reject(error) }
          
          switch(data.flatMap { try? JSONDecoder().decode(RpcResponse.self, from: $0) }?.result ) {
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
      .map { result in
        return try JSONDecoder().decode(OUTPUT.self, from: Data(result.result))
      }
  }
  
}
