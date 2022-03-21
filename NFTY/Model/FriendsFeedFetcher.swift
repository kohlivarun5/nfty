//
//  FriendsFeedFetcher.swift
//  NFTY
//
//  Created by Varun Kohli on 3/20/22.
//

import Foundation
import Web3
import Web3ContractABI

class FriendsFeedFetcher {
  
  let logsFetcher : LogsFetcher
  
  let Transfer: SolidityEvent = SolidityEvent(name: "Transfer", anonymous: false, inputs: [
    SolidityEvent.Parameter(name: "from", type: .address, indexed: true),
    SolidityEvent.Parameter(name: "to", type: .address, indexed: true),
    SolidityEvent.Parameter(name: "tokenId", type: .uint256, indexed: true),
  ])
  
  
  init(addresses:[EthereumAddress]) {
    let cacheId = "FriendsFeedFetcher.initFromBlock"
    let fromBlock = (UserDefaults.standard.string(forKey: cacheId).flatMap { BigUInt($0)}) ?? INIT_BLOCK
    // create topiocs
    self.logsFetcher = LogsFetcher(
      event: self.Transfer,
      fromBlock: fromBlock,
      address: nil,
      cacheId : cacheId,
      topics: [
        EthereumGetLogTopics.and(nil),
        EthereumGetLogTopics.or(
          addresses.map {
            try! ABI.encodeParameter(SolidityWrappedValue.address($0))
          }
        )
      ],
      blockDecrements: 5)
  }
  
  func getRecentEvents(onDone: @escaping () -> Void, _ response: @escaping (NFTWithPrice) -> Void) {
    onDone()
  }
  
  func refreshLatestEvents(onDone: @escaping () -> Void, _ response: @escaping (NFTWithPrice) -> Void) {
    onDone()
  }
  
}
