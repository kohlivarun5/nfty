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
    let blockDecrements = BigUInt(addresses.count <= 1 ? 10000: 5000)
    self.logsFetcher = LogsFetcher(
      event: self.Transfer,
      fromBlock: fromBlock - blockDecrements,
      address: nil,
      cacheId : cacheId,
      topics: [
        EthereumGetLogTopics.or(
          addresses.map {
            try! ABI.encodeParameter(SolidityWrappedValue.address($0))
          }
        ),
        EthereumGetLogTopics.and(nil),
      ],
      blockDecrements: blockDecrements)
    self.addresses = addresses
  }
  
  func getRecentEvents(onDone: @escaping () -> Void, _ response: @escaping (NFTItem) -> Void) {
    var processed : Promise<Int> = Promise.value(0)
    
    self.logsFetcher.fetchWithPromise(onDone: { (isFinal:Bool) in
      return processed.map { processed in
        if (isFinal || processed != 0) {
          // print("done")
          onDone()
        }
        return processed
      }
    },limit:2,retries:20) { log in
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
              // if (self.addresses.first(where: { $0 == txInfo.from }) == nil) { return processed }
              // TODO Fix : Bring price from tx /WETH
              // print("log=",tokenId,log.transactionHash?.hex())
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
                      },
                      action:Action(account: UserAccount(ethAddress: res["from"] as? EthereumAddress, nearAccount: nil),
                                    action: .sold)
                    ),
                    info: collection.info),
                  collection: collection)
              )
              return processed + 1
              
            }
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
      _ = prev.done { onDone() }
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
            // TODO Fix : Bring price from tx /WETH
            _ = txFetcher.eventOfTx(transactionHash: log.transactionHash)
              .map { txInfo in
                
                guard let txInfo = txInfo else { return }
                
                guard let price = priceIfNotZero(txInfo.value) else { return }
                // if (self.addresses.first(where: { $0 == txInfo.from }) == nil) { return processed }
                // TODO Fix : Bring price from tx /WETH
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
              }
          }.recover { error -> Promise<Void> in
            print(error)
            return Promise.value(())
          }
      }
      prev = p
    }
  }
  
}
