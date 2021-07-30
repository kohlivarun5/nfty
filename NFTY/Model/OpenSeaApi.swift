//
//  OpenSeaApi.swift
//  NFTY
//
//  Created by Varun Kohli on 7/30/21.
//

import Foundation
import Web3
import PromiseKit


struct OpenSeaApi {
  
  static func getBidAsk(contract:EthereumAddress,tokenId:UInt) -> Promise<BidAsk> {
    
    struct SellOrder : Codable {
      let current_price : String
      let payment_token : String
    }
    
    struct Asset: Codable {
      let sell_orders : [SellOrder]
    }
    
    struct AssetOrders: Codable {
      var assets: [Asset]
    }
    
    
    return Promise { seal in
      var request = URLRequest(
        url: URL(
          string: "https://api.opensea.io/api/v1/assets?token_ids=\(tokenId)&asset_contract_address=\(contract.hex(eip55:false))&order_direction=desc")!)
      
      request.httpMethod = "GET"
      
      URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
        do {
          //print(data.map { String(decoding: $0, as: UTF8.self)})
          let jsonDecoder = JSONDecoder()
          let assets = try jsonDecoder.decode(AssetOrders.self, from: data!)
          print(assets)
          
          switch(assets.assets[safe:0]?.sell_orders[safe:0]) {
          case .none:
            seal.fulfill(BidAsk(bid:nil,ask:nil))
          case .some(let order):
            switch(order.payment_token,Double(order.current_price).map { BigUInt($0) }) {
            case ("0x0000000000000000000000000000000000000000",.some(let wei)):
              seal.fulfill(BidAsk(bid:nil,ask:AskInfo(wei: wei)))
            default:
              seal.fulfill(BidAsk(bid:nil,ask:nil))
            }
          }
        } catch {
          print("JSON Serialization error:\(error), json=\(data.map { String(decoding: $0, as: UTF8.self) } ?? "")")
          seal.reject(NSError(domain:"", code:404, userInfo:nil))
        }
      }).resume()
    }
  }
}


struct OpenSeaTradeApi : TokenTradeInterface {
  var supportsTrading : Bool = false
  
  let contract : EthereumAddress
  
  func getBidAsk(_ tokenId: UInt) -> Promise<BidAsk> {
    return OpenSeaApi.getBidAsk(contract: contract,tokenId: tokenId)
  }
}
