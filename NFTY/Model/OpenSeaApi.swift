//
//  OpenSeaApi.swift
//  NFTY
//
//  Created by Varun Kohli on 7/30/21.
//

import Foundation
import Web3
import PromiseKit


let ETH_ADDRESS = "0x0000000000000000000000000000000000000000"

let WETH_ADDRESS = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"

struct OpenSeaApi {
  
  static func getBidAsk(contract:EthereumAddress,tokenId:UInt) -> Promise<BidAsk> {
    
    struct SellOrder : Codable {
      let current_price : String
      let payment_token : String
    }
    
    struct Asset: Codable {
      let sell_orders : [SellOrder]?
    }
    
    struct AssetOrders: Codable {
      var assets: [Asset]
    }
    
    
    return Promise { seal in
      var request = URLRequest(
        url: URL(
          string: "https://api.opensea.io/api/v1/assets?token_ids=\(tokenId)&asset_contract_address=\(contract.hex(eip55:false))&order_direction=desc")!)
      
      request.httpMethod = "GET"
      
      print("calling \(request.url!)")
      URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
        do {
          //print(data.map { String(decoding: $0, as: UTF8.self)})
          let jsonDecoder = JSONDecoder()
          let assets = try jsonDecoder.decode(AssetOrders.self, from: data!)
          // print(assets)
          
          switch(assets.assets[safe:0]?.sell_orders?[safe:0]) {
          case .none:
            seal.fulfill(BidAsk(bid:nil,ask:nil))
          case .some(let order):
            switch(order.payment_token,Double(order.current_price).map { BigUInt($0) }) {
            case (ETH_ADDRESS,.some(let wei)),
                 (WETH_ADDRESS,.some(let wei)):
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
  
  enum Side : Int,Codable {
    case buy = 0
    case sell = 1
  }
  
  static func userOrders(maker:EthereumAddress,side:Side?) -> Promise<[NFTWithLazyPrice]> {
    
    struct AssetContract: Codable {
      let address: String
    }
    struct Asset: Codable {
      let token_id : String
      let asset_contract: AssetContract
    }
    
    
    struct AssetOrders: Codable {
      let asset: Asset
      let current_price : String
      let payment_token : String
      let side : Side
      let expiration_time : UInt
      
      static func sideToEvent(_ side:Side) -> TradeEventType {
        switch (side) {
        case .buy:
          return TradeEventType.bid
        case .sell:
          return TradeEventType.ask
        }
      }
      
      
    }
    
    struct Orders : Codable {
      let orders : [AssetOrders]
    }
    
    var urlString = "https://api.opensea.io/wyvern/v1/orders?maker=\(maker.hex(eip55: true))&bundled=false&include_bundled=false&include_invalid=false&offset=0&order_by=created_date&order_direction=desc"
    
    _ = side.map {
      urlString = "\(urlString)&side=\($0.rawValue)"
    }
    
    return Promise { seal in
      var request = URLRequest(url: URL(string:urlString)!)
      
      request.httpMethod = "GET"
      
      print("calling \(request.url!)")
      URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
        do {
          let jsonDecoder = JSONDecoder()
          // print(data)
          let orders = try jsonDecoder.decode(Orders.self, from: data!)
          
          //print(orders)
          
          seal.fulfill(
            orders.orders
              .sorted {
                switch($0.expiration_time,$1.expiration_time) {
                case (0,0):
                  return false
                case (0,_):
                  return false
                case (_,0):
                  return true
                default:
                  return $0.expiration_time < $1.expiration_time
                }
              }
              .map { order in
                collectionsFactory
                  .getByAddress(
                    try! EthereumAddress(hex: order.asset.asset_contract.address, eip55: false)
                      .hex(eip55: true))
                  .flatMap { collection in
                    UInt(order.asset.token_id).map {
                      collection.data.contract.getNFT($0)
                    }
                  }
                  .flatMap { (nft:NFT) -> NFTWithLazyPrice? in
                    switch(order.payment_token,Double(order.current_price).map { BigUInt($0) }) {
                    case (ETH_ADDRESS,.some(let wei)),
                         (WETH_ADDRESS,.some(let wei)):
                      return NFTWithLazyPrice(
                        nft: nft,
                        getPrice: {
                          ObservablePromise<NFTPriceStatus>(
                            resolved: NFTPriceStatus.known(
                              NFTPriceInfo(
                                price: wei,
                                blockNumber: nil,
                                type:AssetOrders.sideToEvent(order.side))
                            )
                          )
                        })
                    default:
                      return nil
                    }
                  }
              }
              .filter { $0 != nil }
              .map { $0! }
            
          )
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
