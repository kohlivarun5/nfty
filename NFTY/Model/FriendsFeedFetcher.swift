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
  
  private func actionAccount(res:[String : Any]) -> EthereumAddress? {
    switch(self.action) {
    case .sold:
      return res["from"] as? EthereumAddress
    case .bought:
      return res["to"] as? EthereumAddress
    case .minted:
      return res["to"] as? EthereumAddress
    }
  }
  
  init(from:[EthereumAddress],fromBlock:BigUInt,limit:Int) {
    let cacheId = "FriendsFeedFetcher.initFromBlock"
    let blockDecrements = BigUInt(500)
    self.limit = limit
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
  
  init(from:[EthereumAddress],to:[EthereumAddress],action:Action.ActionType,fromBlock:BigUInt,limit:Int) {
    let cacheId = "FriendsFeedFetcher.initFromBlock"
    let blockDecrements = BigUInt(5000)
    self.limit = limit
    self.retries = 10
    self.addressesFilter = to
    self.action = action
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
        if (isFinal || processed >= self.limit) {
            // print("done")
          onDone()
        }
        return processed
      }
    },onRetry:onRetry,limit:self.limit,retries:self.retries) { logs in
      
      let total = logs.count
      
      struct LogData {
        let tokenId : BigUInt
        let transactionHash : EthereumData
        let actionAccount : EthereumAddress
        let contractAddress : EthereumAddress
        let blockNumber: EthereumQuantity
        let res : [String : Any]
      }
      
      let grouped = Dictionary(
        grouping:
          logs
          .compactMap { log -> LogData? in
            let res = try! web3.eth.abi.decodeLog(event:self.Transfer,from:log);
            guard let tokenId = (res["tokenId"] as? BigUInt) else { return nil }
            
              // guard let removed = log.removed && !removed else { return nil }
            guard let transactionHash = log.transactionHash else { return nil }
            guard let actionAccount = self.actionAccount(res: res) else { return nil }
            guard let blockNumber = log.blockNumber else { return nil }
            
            return LogData(
              tokenId: tokenId,
              transactionHash:transactionHash,
              actionAccount: actionAccount,
              contractAddress:log.address,
              blockNumber:blockNumber,
              res: res)
          },
        by: { "\($0.actionAccount.hex(eip55:true)):\($0.transactionHash.hex())" })
      
      var current = 0
      processed = processed.then {
        reduce_p(grouped.map { $1 }, $0, { processed,logsData -> Promise<Int>in
          
          let actionCount = logsData.count
          current = current + actionCount
          
          let progress = LoadingProgress(current: current, total: total)
          
          guard let logData = logsData.sorted(by: { a,b in a.blockNumber.quantity > b.blockNumber.quantity }).first else { return Promise.value(processed) }
          
          let transactionHash = logData.transactionHash
          let actionAccount = logData.actionAccount
          let tokenId = logData.tokenId
          
          return TxFetcher.eventOfTx(transactionHash:transactionHash)
            .then { txInfo -> Promise<Int> in
              
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
              
                // print("Log for Address=\(log.address.hex(eip55: true))");
              return collectionsFactory.getByAddressOpt(logData.contractAddress.hex(eip55: true))
                .map  { collectionOpt -> Int in
                  
                  guard let collection = collectionOpt else { return processed }
                  
                    // TODO Fix : Bring price from tx /WETH
                    // print("log=",tokenId,log.transactionHash?.hex())
                  response(
                    progress,
                    FriendsFeedFetcher.NFTItem(
                      nft: NFTWithPriceAndInfo(
                        nftWithPrice: NFTWithPrice(
                          nft:collection.contract.getNFT(tokenId),
                          blockNumber: .ethereum(logData.blockNumber),
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
                          action:Action(account: UserAccount(ethAddress: actionAccount,
                                                             nearAccount: nil),
                                        action: self.action,
                                        count: actionCount)
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
        })
      }
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
              // let isMint = res["from"] as! EthereumAddress == EthereumAddress(hexString:ETH_ADDRESS)!
              // TODO Fix : Bring price from tx /WETH
            TxFetcher.eventOfTx(transactionHash: log.transactionHash)
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
