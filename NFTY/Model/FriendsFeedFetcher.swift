//
//  FriendsFeedFetcher.swift
//  NFTY
//
//  Created by Varun Kohli on 3/20/22.
//

import Foundation
import Web3
import Web3ContractABI
import PromiseKit

class FriendsFeedFetcher {
  
  struct NFTItem {
    let nft : NFTWithPriceAndInfo
    let collection : Collection
  }
  
  let logsFetcher : LogsFetcher
  
  let Transfer: SolidityEvent = SolidityEvent(name: "Transfer", anonymous: false, inputs: [
    SolidityEvent.Parameter(name: "from", type: .address, indexed: true),
    SolidityEvent.Parameter(name: "to", type: .address, indexed: true),
    SolidityEvent.Parameter(name: "tokenId", type: .uint256, indexed: true),
  ])
  
  
  init(addresses:[EthereumAddress],fromBlock:BigUInt) {
    let cacheId = "FriendsFeedFetcher.initFromBlock"
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
  
  func getRecentEvents(onDone: @escaping () -> Void, _ response: @escaping (NFTItem) -> Void) {
    var prev : Promise<Void> = Promise.value(())
    
    self.logsFetcher.fetch(onDone: {
      prev.done { onDone() }
    }) { log in
      
      let p = prev.then { collectionsFactory.getByAddress(log.address.hex(eip55: true)) }
        .map  { collection -> Void in
          
          print("Address=\(collection.contract.contractAddressHex)")
          
          let res = try! web3.eth.abi.decodeLog(event:self.Transfer,from:log);
          guard let tokenId = ((res["tokenId"] as? BigUInt).flatMap { UInt($0) }) else { return }
          // let isMint = res["from"] as! EthereumAddress == EthereumAddress(hexString: "0x0000000000000000000000000000000000000000")!
          
          return response(
            FriendsFeedFetcher.NFTItem(
              nft: NFTWithPriceAndInfo(
                nftWithPrice: NFTWithPrice(
                  nft:collection.contract.getNFT(tokenId),
                  blockNumber: log.blockNumber.map { .ethereum($0) },
                  indicativePrice:.lazy {
                    ObservablePromise(resolved:NFTPriceStatus.unavailable)
                  }),
                info: collection.info),
              collection: collection)
            )
                
                      // TODO Fix
                      /* self.ethContract.eventOfTx(transactionHash:log.transactionHash,eventType:isMint ? .minted : .bought)
                       .map {
                       let price = priceIfNotZero($0?.value);
                       return NFTPriceStatus.known(
                       NFTPriceInfo(
                       wei:price,
                       blockNumber: log.blockNumber.map { .ethereum($0) },
                       type: isMint ? .minted : price.map { _ in TradeEventType.bought } ?? TradeEventType.transfer))
                       }
                       */
        }.recover { error -> Promise<Void> in
          print(error)
          return Promise.value(())
        }
      prev = p
    }
  }
  
  func refreshLatestEvents(onDone: @escaping () -> Void, _ response: @escaping (NFTItem) -> Void) {
    onDone()
  }
  
}
