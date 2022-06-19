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
  
  let limit : Int
  let retries : Int
  
  let addressesFilter : [EthereumAddress]?
  
  let action : Action.ActionType
  
  private func actionOfLog(res:[String : Any]) -> Action {
    switch(self.action) {
    case .sold:
      return Action(account: UserAccount(ethAddress: res["from"] as? EthereumAddress, nearAccount: nil),
                    action:self.action)
    case .bought:
      return Action(account: UserAccount(ethAddress: res["to"] as? EthereumAddress, nearAccount: nil),
                    action:self.action)
    }
  }
  
  init(from:[EthereumAddress],fromBlock:BigUInt) {
    let cacheId = "FriendsFeedFetcher.initFromBlock"
    let blockDecrements = BigUInt(500)
    self.limit = 2
    self.retries = 10
    self.addressesFilter = nil
    self.action = .sold
    self.logsFetcher = LogsFetcher(
      event: self.Transfer,
      fromBlock: fromBlock - blockDecrements,
      address: nil,
      cacheId : cacheId,
      topics: [
        from.count == 1
        ? EthereumGetLogTopics.and(try! ABI.encodeParameter(SolidityWrappedValue.address(from[0])))
        : EthereumGetLogTopics.or(
          from.map {
            try! ABI.encodeParameter(SolidityWrappedValue.address($0))
          }
        ),
        EthereumGetLogTopics.and(nil),
      ],
      blockDecrements: blockDecrements)
  }
  
  init(to:[EthereumAddress],fromBlock:BigUInt) {
    let cacheId = "FriendsFeedFetcher.initFromBlock"
    let blockDecrements = BigUInt(500)
    self.limit = 1
    self.retries = 10
    self.addressesFilter = to
    self.action = .bought
    self.logsFetcher = LogsFetcher(
      event: self.Transfer,
      fromBlock: fromBlock - blockDecrements,
      address: nil,
      cacheId : cacheId,
      topics: [
        EthereumGetLogTopics.and(nil),
        to.count == 1
        ? EthereumGetLogTopics.and(try! ABI.encodeParameter(SolidityWrappedValue.address(to[0])))
        : EthereumGetLogTopics.or(
          to.map {
            try! ABI.encodeParameter(SolidityWrappedValue.address($0))
          }
        )
      ],
      blockDecrements: blockDecrements)
  }
  
  func getRecentEvents(onDone: @escaping () -> Void,_ onRetry: @escaping () -> Void, _ response: @escaping (LoadingProgress,NFTItem) -> Void) {
    var processed : Promise<Int> = Promise.value(0)
    
    print("getRecentEvents")
    self.logsFetcher.fetchWithPromise(onDone: { (isFinal:Bool) in
      return processed.map { processed in
        if (isFinal || processed != 0) {
          // print("done")
          onDone()
        }
        return processed
      }
    },onRetry:onRetry,limit:self.limit,retries:self.retries) { progress,log in
      let p = processed.then { processed -> Promise<Int> in
        
        let res = try! web3.eth.abi.decodeLog(event:self.Transfer,from:log);
        
        print("Processing log \(progress)")
        
        guard let tokenId = (res["tokenId"] as? BigUInt) else { return Promise.value(processed)  }
        // let isMint = res["from"] as! EthereumAddress == EthereumAddress(hexString: "0x0000000000000000000000000000000000000000")!
        
        guard let removed = log.removed else { return Promise.value(processed) }
        if (removed) { return Promise.value(processed) }
        
        guard let transactionHash = log.transactionHash else { return Promise.value(processed) }
        
        print("eventOfTx for ",transactionHash.hex())
        return txFetcher.eventOfTx(transactionHash:transactionHash)
          .then { txInfo -> Promise<Int> in
        
            print("txInfo=\(txInfo)")
            guard let txInfo = txInfo else { return Promise.value(processed) }
            
            switch(self.addressesFilter) {
            case .some(let filter):
              if (filter.first(where: { $0 == txInfo.from }) == nil) {
                // tx from is not one of requested addresses, skip such as can be spam
                return Promise.value(processed)
              }
            case .none:
              break
            }
            
            guard let price = priceIfNotZero(txInfo.value) else { return Promise.value(processed) }
            
            print("Log for Address=\(log.address.hex(eip55: true))");
            return collectionsFactory.getByAddressOpt(log.address.hex(eip55: true))
              .map  { collectionOpt -> Int in
                print("collectionOpt=\(collectionOpt)")
                
                guard let collection = collectionOpt else { return processed }
                
                // TODO Fix : Bring price from tx /WETH
                // print("log=",tokenId,log.transactionHash?.hex())
                response(
                  progress,
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
                        action:self.actionOfLog(res:res)
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
  
  func refreshLatestEvents(onDone: @escaping () -> Void, _ response: @escaping (LoadingProgress,NFTItem) -> Void) {
    var prev : Promise<Void> = Promise.value(())
    
    print("refreshLatestEvents")
    self.logsFetcher.updateLatest(onDone: {
      prev.done { onDone() }.catch { print($0); onDone() }
    }) { (progress,log) in
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
            txFetcher.eventOfTx(transactionHash: log.transactionHash)
              .map { txInfo in
                
                guard let txInfo = txInfo else { return }
                
                guard let price = priceIfNotZero(txInfo.value) else { return }
                // if (self.addresses.first(where: { $0 == txInfo.from }) == nil) { return processed }
                // TODO Fix : Bring price from tx /WETH
                response(
                  progress,
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
              .catch { print($0) }
          }.recover { error -> Promise<Void> in
            print(error)
            return Promise.value(())
          }
      }
      prev = p
    }
  }
  
}
