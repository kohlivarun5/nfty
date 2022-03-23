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
  
  let addresses : [EthereumAddress]
  
  init(addresses:[EthereumAddress],fromBlock:BigUInt) {
    let cacheId = "FriendsFeedFetcher.initFromBlock"
    let blockDecrements = BigUInt(500)
    self.logsFetcher = LogsFetcher(
      event: self.Transfer,
      fromBlock: fromBlock - blockDecrements,
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
      blockDecrements: blockDecrements)
    self.addresses = addresses
  }
  
  func getRecentEvents(onDone: @escaping () -> Void, _ response: @escaping (NFTItem) -> Void) {
    var processed : Promise<Int> = Promise.value(0)
    
    self.logsFetcher.fetchWithPromise(onDone: { (isFinal:Bool) in
      return processed.map { processed in
        if (isFinal || processed != 0) {
          print("done")
          onDone()
        }
        return processed
      }
    },retries: 10) { log in
      let p = processed.then { processed -> Promise<Int> in
        
        //print("Log for Address=\(log.address.hex(eip55: true))");
        return collectionsFactory.getByAddressOpt(log.address.hex(eip55: true))
        .then  { collectionOpt -> Promise<Int> in
          
          guard let collection = collectionOpt else { return Promise.value(processed) }
          
          let res = try! web3.eth.abi.decodeLog(event:self.Transfer,from:log);
          
          // print("Found Collection Address=\(collection.contract.contractAddressHex),tokenId=\(res["tokenId"] as? BigUInt) for log=\(log)")
          
          guard let tokenId = (res["tokenId"] as? BigUInt) else { return Promise.value(processed)  }
          // let isMint = res["from"] as! EthereumAddress == EthereumAddress(hexString: "0x0000000000000000000000000000000000000000")!
          
          return txFetcher.eventOfTx(transactionHash: log.transactionHash)
            .map { txInfo -> Int in
              
              guard let txInfo = txInfo else { return processed }
              
              guard let price = priceIfNotZero(txInfo.value) else { return processed }
              //if (price == nil && self.addresses.first(where: { $0 == txInfo.from }) == nil) { return }
              
              response(
                FriendsFeedFetcher.NFTItem(
                  nft: NFTWithPriceAndInfo(
                    nftWithPrice: NFTWithPrice(
                      nft:collection.contract.getNFT(tokenId),
                      blockNumber: log.blockNumber.map { .ethereum($0) },
                      indicativePrice:.lazy {
                        ObservablePromise(
                          resolved:NFTPriceStatus.known(
                            NFTPriceInfo(
                              wei: price,
                              blockNumber:.ethereum(txInfo.blockNumber),
                              type: .transfer
                            )
                          )
                        ) // TODO
                      }),
                    info: collection.info),
                  collection: collection)
              )
              return processed + 1
              
            }
          
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
        }.recover { error -> Promise<Int> in
          print(error)
          return Promise.value(processed)
        }
      }
      processed = p
    }
  }
  
  func refreshLatestEvents(onDone: @escaping () -> Void, _ response: @escaping (NFTItem) -> Void) {
    var prev : Promise<Void> = Promise.value(())
    
    self.logsFetcher.updateLatest(onDone: {
      prev.done {
        print("done")
        onDone()
      }
    }) { (index,log) in
      let p = prev.then { () -> Promise<Void> in
        
        //print("Log for Address=\(log.address.hex(eip55: true))");
        return collectionsFactory.getByAddressOpt(log.address.hex(eip55: true))
          .map  { collectionOpt -> Void in
            
            guard let collection = collectionOpt else { return }
            
            let res = try! web3.eth.abi.decodeLog(event:self.Transfer,from:log);
            
            // print("Found Collection Address=\(collection.contract.contractAddressHex),tokenId=\(res["tokenId"] as? BigUInt) for log=\(log)")
            
            guard let tokenId = (res["tokenId"] as? BigUInt) else { return }
            // let isMint = res["from"] as! EthereumAddress == EthereumAddress(hexString: "0x0000000000000000000000000000000000000000")!
            
            return response(
              FriendsFeedFetcher.NFTItem(
                nft: NFTWithPriceAndInfo(
                  nftWithPrice: NFTWithPrice(
                    nft:collection.contract.getNFT(tokenId),
                    blockNumber: log.blockNumber.map { .ethereum($0) },
                    indicativePrice:.lazy {
                      ObservablePromise(resolved:NFTPriceStatus.unavailable) // TODO
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
      }
      prev = p
    }
  }
  
}
