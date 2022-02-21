//
//  NearApi.swift
//  NFTY
//
//  Created by Varun Kohli on 1/26/22.
//

import Foundation
import PromiseKit
import BigInt

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
      
      var request = URLRequest(url: url)
      request.httpMethod = params.flatMap {_ in "POST"} ?? "GET"
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = params.flatMap { try? JSONSerialization.data(withJSONObject: $0, options: []) }
      return Promise.init { seal in
        print("Calling \(request.url!)")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
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
            // print(result.logs)
            // print(String(data:Data(result.result),encoding:.ascii) as Any)
            return try JSONDecoder().decode(OUTPUT.self, from: Data(result.result))
          }
      }
  
  /*
   https://docs.near.org/docs/api/rpc/block-chunk#block-details
   {
   "jsonrpc": "2.0",
   "id": "dontcare",
   "method": "block",
   "params": {
   "block_id": 17821130
   }
   }
   */
  
  public struct BlockInfo: Decodable {
    
    struct Header : Decodable {
      let timestamp : UInt64
    }
    let author : String
    let header : Header
  }
  
  static func block(block_id:BigUInt) -> Promise<BlockInfo?> {
    
    guard let block_id_uint = try? UInt64(block_id) else { return Promise.value(nil) }
    
    let request: [String: Any] = [
      "jsonrpc": "2.0",
      "id": "dontcare",
      "method": "block",
      "params": [
        "block_id": block_id_uint
      ]
    ]
    return Impl.fetch(url:URL(string:"https://archival-rpc.mainnet.near.org")!, params: request)
  }
}
