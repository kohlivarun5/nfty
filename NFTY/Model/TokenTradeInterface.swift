//
//  TokenTradeInterface.swift
//  NFTY
//
//  Created by Varun Kohli on 7/25/21.
//

import Foundation
import PromiseKit
import BigInt

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

protocol TokenTradeInterface {
  var supportsTrading : Bool { get }
  func getBidAsk(_ tokenId:UInt) -> Promise<BidAsk>
  
  // func withdrawAsk(_ tokenId:Uint) -> Promise<BigUInt>
}
