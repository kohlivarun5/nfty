//
//  TokenTradeInterface.swift
//  NFTY
//
//  Created by Varun Kohli on 7/25/21.
//

import Foundation
import PromiseKit
import BigInt


protocol TokenTradeInterface {
  func getBidPrice(_ tokenId:UInt) -> Promise<BigUInt?>
  func getAskPrice(_ tokenId:UInt) -> Promise<BigUInt?>
  
  // func withdrawAsk(_ tokenId:Uint) -> Promise<BigUInt>
}
