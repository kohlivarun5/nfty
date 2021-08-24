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
}

struct AskInfo {
  let wei : BigUInt
}

struct BidAsk {
  let bid : BidInfo?
  let ask : AskInfo?
}

protocol TradeActionsInterface {
  func submitBid(tokenId: UInt, wei: BigUInt, wallet: WalletProvider) -> Promise<EthereumTransactionReceiptObject>
}

protocol TokenTradeInterface {
  func getBidAsk(_ tokenId:UInt) -> Promise<BidAsk>
  var actions : TradeActionsInterface? { get }
}
