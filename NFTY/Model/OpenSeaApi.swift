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
  
  enum Side : Int,Codable {
    case buy = 0
    case sell = 1
  }
  
  enum QueryAddress {
    case maker(EthereumAddress)
    case owner(EthereumAddress)
  }
  
  
  struct AssetContract: Codable {
    let address: String
  }
  struct Asset: Codable {
    let token_id : String
    let asset_contract: AssetContract
  }
  
  
  struct AssetOrder: Codable {
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
    let orders : [AssetOrder]
  }
  
  static func getOrders(contract:String?,tokenIds:[UInt]?,user:QueryAddress?,side:Side?) -> Promise<[AssetOrder]> {
    
    var components = URLComponents()
    components.scheme = "https"
    components.host = "api.opensea.io"
    components.path = "/wyvern/v1/orders"
    components.queryItems = [
      URLQueryItem(name: "bundled", value: String(false)),
      URLQueryItem(name: "include_bundled", value: String(false)),
      URLQueryItem(name: "include_invalid", value: String(false)),
      URLQueryItem(name: "offset", value: String(0)),
      URLQueryItem(name: "order_by", value: "created_date"),
      URLQueryItem(name: "order_direction", value: "desc"),
    ]
    
    contract.map {
      components.queryItems?.append(URLQueryItem(name: "asset_contract_address", value: $0))
    }
    
    tokenIds.map {
      $0.forEach {
        components.queryItems?.append(URLQueryItem(name: "token_ids", value: String($0)))
      }
    }
    
    switch(user) {
    case .maker(let maker):
      components.queryItems?.append(URLQueryItem(name: "maker", value: maker.hex(eip55: true)))
    case .owner(let owner):
      components.queryItems?.append(URLQueryItem(name: "owner", value: owner.hex(eip55: true)))
    case .none:
      break
    }
    
    side.map {
      components.queryItems?.append(URLQueryItem(name: "side", value: String($0.rawValue)))
    }
    
    return Promise { seal in
      var request = URLRequest(url:components.url!)
      
      request.httpMethod = "GET"
      
      print("calling \(request.url!)")
      URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
        do {
          let jsonDecoder = JSONDecoder()
          // print(data)
          var orders = try jsonDecoder.decode(Orders.self, from: data!)
          
          //print(orders)
          // remove duplicates, we request ordered by highest first
          if (contract == nil || tokenIds == nil) {
            var uniqueOrdersDict : [String:AssetOrder] = [:]
            orders.orders.forEach { order in
              let key = "\(order.asset.asset_contract.address):\(order.asset.token_id)"
              uniqueOrdersDict[key] = uniqueOrdersDict[key] ?? order
            }
            
            orders = Orders(orders: uniqueOrdersDict.map { $1 })
          }
          
          seal.fulfill(orders.orders)
          
        } catch {
          print("JSON Serialization error:\(error), json=\(data.map { String(decoding: $0, as: UTF8.self) } ?? "")")
          seal.reject(NSError(domain:"", code:404, userInfo:nil))
        }
      }).resume()
    }
  }
  
  static func getBidAsk(contract:String,tokenIds:[UInt],side:Side?) -> Promise<[UInt:BidAsk]> {
    OpenSeaApi.getOrders(contract: contract, tokenIds: tokenIds, user: nil, side: side)
      .map { orders in
        
        var dict : [UInt:[AssetOrder]] = [:]
        tokenIds.forEach { id in
          dict[id] = orders.filter { $0.asset.token_id == String(id) }
        }
        
        return dict.mapValues {
          
          let ask = $0.first { $0.side == .sell }.flatMap { (order:AssetOrder) -> AskInfo? in
            switch(order.payment_token,Double(order.current_price).map { BigUInt($0) }) {
            case (ETH_ADDRESS,.some(let wei)),
                 (WETH_ADDRESS,.some(let wei)):
              return AskInfo(wei: wei)
            default:
              return nil
            }
          }
          
          let bid = $0.first { $0.side == .buy }.flatMap { (order:AssetOrder) -> BidInfo? in
            switch(order.payment_token,Double(order.current_price).map { BigUInt($0) }) {
            case (ETH_ADDRESS,.some(let wei)),
                 (WETH_ADDRESS,.some(let wei)):
              return BidInfo(wei: wei)
            default:
              return nil
            }
          }
          return BidAsk(bid: bid, ask: ask)
        }
      }
  }
  
  static func getBidAsk(contract:String,tokenId:UInt) -> Promise<BidAsk> {
    OpenSeaApi.getOrders(contract: contract, tokenIds: [tokenId], user: nil, side: nil)
      .map {
        let ask = $0.first { $0.side == .sell }.flatMap { (order:AssetOrder) -> AskInfo? in
          switch(order.payment_token,Double(order.current_price).map { BigUInt($0) }) {
          case (ETH_ADDRESS,.some(let wei)),
               (WETH_ADDRESS,.some(let wei)):
            return AskInfo(wei: wei)
          default:
            return nil
          }
        }
        
        let bid = $0.first { $0.side == .buy }.flatMap { (order:AssetOrder) -> BidInfo? in
          switch(order.payment_token,Double(order.current_price).map { BigUInt($0) }) {
          case (ETH_ADDRESS,.some(let wei)),
               (WETH_ADDRESS,.some(let wei)):
            return BidInfo(wei: wei)
          default:
            return nil
          }
        }
        return BidAsk(bid: bid, ask: ask)
      }
  }
  
  
  static func userOrders(address:QueryAddress,side:Side?) -> Promise<[NFTWithLazyPrice]> {
    OpenSeaApi.getOrders(contract: nil, tokenIds: nil, user: address, side: side)
      .map { orders in
        orders
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
                            type:AssetOrder.sideToEvent(order.side))
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
      }
  }
  
}


struct OpenSeaTradeApi : TokenTradeInterface {
  var actions: TradeActionsInterface? = nil
  
  let contract : EthereumAddress
  
  func getBidAsk(_ tokenId: UInt) -> Promise<BidAsk> {
    return OpenSeaApi.getBidAsk(contract: contract.hex(eip55: true),tokenId: tokenId)
  }
}
