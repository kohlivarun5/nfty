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
  let wei : BigUInt
  let expiration_time : UInt?
}

struct AskInfo {
  let wei : BigUInt
  let expiration_time : UInt?
}

struct BidAsk {
  let bid : BidInfo?
  let ask : AskInfo?
}

protocol TradeActionsInterface {
  func submitBid(tokenId: UInt, wei: BigUInt, wallet: WalletProvider) -> Promise<EthereumTransactionReceiptObject>
  
  func acceptOffer(tokenId: UInt, wei: BigUInt, wallet: WalletProvider) -> Promise<EthereumTransactionReceiptObject>
}

enum Side {
  case bid
  case ask
}

protocol TokenTradeInterface {
  func getBidAsk(_ tokenId:UInt,_ side:Side?) -> Promise<BidAsk>
  func getBidAsk(_ tokenIds:[UInt],_ side:Side?) -> Promise<[(tokenId:UInt,bidAsk:BidAsk)]>
  var actions : TradeActionsInterface? { get }
}

func getBidAskSerial(tokenIds:[UInt],_ side:Side?,wait:Double,getter: @escaping (_ tokenId:UInt,_ side:Side?) -> Promise<BidAsk>) -> Promise<[(tokenId:UInt,bidAsk:BidAsk)]> {
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
