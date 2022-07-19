//
//  TokenTradeInterface.swift
//  NFTY
//
//  Created by Varun Kohli on 7/25/21.
//

import Foundation
import PromiseKit
import BigInt
import Web3

struct BidInfo {
  let price : PriceUnit
  let expiration_time : UInt?
}

struct AskInfo {
  let price : PriceUnit
  let expiration_time : UInt?
}

struct BidAsk {
  let bid : BidInfo?
  let ask : AskInfo?
}

protocol TradeActionsInterface {
  func submitBid(tokenId: BigUInt, wei: BigUInt, wallet: WalletProvider) -> Promise<EthereumData>
  
  func acceptOffer(tokenId: BigUInt, wei: BigUInt, wallet: WalletProvider) -> Promise<EthereumData>
}

enum Side {
  case bid
  case ask
}

protocol TokenTradeInterface {
  func getBidAsk(_ tokenId:BigUInt,_ side:Side?) -> Promise<BidAsk>
  func getBidAsk(_ tokenIds:[BigUInt],_ side:Side) -> Promise<[(tokenId:BigUInt,bidAsk:BidAsk)]>
  var actions : TradeActionsInterface? { get }
}

func getBidAskSerial(tokenIds:[BigUInt],_ side:Side,wait:Double,getter: @escaping (_ tokenId:BigUInt,_ side:Side?) -> Promise<BidAsk>) -> Promise<[(tokenId:BigUInt,bidAsk:BidAsk)]> {
  return tokenIds.reduce(Promise.value([]), { (accu,tokenId) in
    accu.then { accu in
      getter(tokenId,side)
        .then { ret in after(seconds:wait).map { ret } }
        .map {
          return accu + [(tokenId:tokenId,bidAsk:$0)]
        }
    }
  })
}
