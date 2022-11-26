//
//  ENSTextChangedFeed.swift
//  NFTY
//
//  Created by Varun Kohli on 7/3/22.
//

import Foundation
import Web3
import Web3ContractABI
import PromiseKit

class ENSTextChangedFeed {
  
  struct NFTItem {
    let nft : NFT
    let collection : Collection
  }
  
  struct FeedItem {
    let nft : NFTItem
    let blockNumber : EthereumQuantity
    let address : EthereumAddress
    let ensName : String?
    let key : String
    let value : String
  }
  
  static public func parseENSAvatar(avatar:String) -> Promise<NFTItem?> {
    
    let prefix = "eip155:1/erc721:"
    if !avatar.hasPrefix(prefix) {
      print("Avatar prefix mistmatch for \(avatar)")
      return Promise.value(nil)
    }
    
    print("Avatar follows eip155: \(avatar)")
    
    let str : String = String(avatar.suffix(from:avatar.index(after:avatar.lastIndex(of: ":")!)))
    let index = str.firstIndex(of: "/")!
    let addressStr : String = String(str.prefix(upTo: index))
    print("address = \(addressStr)")
    let tokenIdStr : String = String(str.suffix(from: str.index(after: index)))
    print("tokenId = \(tokenIdStr)")
    
    let address = try? EthereumAddress(hex: addressStr, eip55: false)
    guard let address = address else { print("Address not a match \(addressStr)"); return Promise.value(nil) }
    
    guard let tokenId = BigUInt(tokenIdStr) else { print("TokenId not a match \(tokenIdStr)"); return Promise.value(nil) }
    
    return collectionsFactory.getByAddressOpt(address.hex(eip55: true))
      .map(on:DispatchQueue.global(qos: .userInitiated)) { collectionOpt -> NFTItem? in
        guard let collection : Collection = collectionOpt else { return nil }
        let nft = collection.contract.getNFT(tokenId)
        return NFTItem(nft: nft, collection: collection)
      }
  }
  
  let logsFetcher : LogsFetcher
  
  // TextChanged(bytes32 indexed node, string indexed indexedKey, string key);
  let TextChanged: SolidityEvent = SolidityEvent(name: "TextChanged", anonymous: false, inputs: [
    SolidityEvent.Parameter(name: "node", type: .bytes(length: 32), indexed: true),
    SolidityEvent.Parameter(name: "indexedKey", type: .string, indexed: true),
    SolidityEvent.Parameter(name: "key", type: .string, indexed: false),
  ])
  
  let limit : Int
  let retries : Int
  
  init(key:String?,fromBlock:BigUInt,limit:Int) {
    let cacheId = "ENSTextChangedFeed.initFromBlock"
    let blockDecrements = BigUInt(1500)
    self.limit = limit
    self.retries = 10
    self.logsFetcher = LogsFetcher(
      event: self.TextChanged,
      fromBlock: fromBlock - blockDecrements,
      address: "0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41",
      cacheId : cacheId,
      topics: [
        EthereumGetLogTopics.and(nil),
        EthereumGetLogTopics.and(
          // Strings are encoded as special in events
          // https://docs.soliditylang.org/en/v0.8.15/abi-spec.html#indexed-event-encoding
          key.map { "0x"+$0.sha3(.keccak256) }
        )
      ],
      blockDecrements: blockDecrements)
  }
  
  func getRecentEvents(onDone: @escaping () -> Void,_ onRetry: @escaping () -> Void, _ response: @escaping (LoadingProgress,FeedItem) -> Void) {
    var processed : Promise<Int> = Promise.value(0)
    
    print("getRecentEvents")
    self.logsFetcher.fetchWithPromise(onDone: { (isFinal:Bool) in
      return processed.map { processed in
        if (isFinal || processed >= self.limit) {
          onDone()
        }
        return processed
      }
    },onRetry:onRetry,limit:self.limit,retries:self.retries) { logs in
      
      processed = processed.then { processed -> Promise<Int> in
        let total = logs.count
        var current = 0
        return reduce_p(logs, processed, { processed,log -> Promise<Int> in
          current = current + 1
          let progress = LoadingProgress(current: current, total: total)
            // Use the node hash to get the value, as it is not in the event
          guard let removed = log.removed else { return Promise.value(processed) }
          if (removed) { return Promise.value(processed) }
          
          guard let blockNumber = log.blockNumber else { return Promise.value(processed) }
            // guard let transactionHash = log.transactionHash else { return Promise.value(processed) }
          
          let res = try! web3.eth.abi.decodeLog(event:self.TextChanged,from:log);
          let key = res["key"] as! String
          let namehash = SolidityWrappedValue.fixedBytes(res["node"] as! Data)
          return ENSCached.avatarOwnerOfNamehash(namehash, block: blockNumber.quantity,eth:web3.eth)
            .then(on:DispatchQueue.global(qos: .userInitiated)) { (address,avatar) -> Promise<(NFTItem?,EthereumAddress?,String?)> in
              guard let avatar = avatar else { return Promise.value((nil,address,nil)) }
              return ENSTextChangedFeed.parseENSAvatar(avatar: avatar).map { ($0,address) }
                .then(on:DispatchQueue.global(qos: .userInitiated)) { info -> Promise<(NFTItem?,EthereumAddress?,String?)> in
                  let (item,address) = info
                  guard let _ = item else { return Promise.value((nil,address,nil)) }
                  guard let address = address else { return Promise.value((nil,address,nil)) }
                  return ENSCached.nameOfOwner(address, eth: web3.eth)
                    .map { (item,address,$0) }
                }
            }
            .then(on:DispatchQueue.global(qos: .userInitiated)) { info -> Promise<FeedItem?> in
              
              let (nftItem,address,name) = info
              guard let address = address else { return Promise.value(nil) }
              guard let nftItem = nftItem else { return Promise.value(nil) }
              
              return ENSWrapper.shared.textOfName(namehash: namehash, key: key, block: blockNumber.quantity)
                .map {
                  FeedItem(nft: nftItem, blockNumber: blockNumber, address: address, ensName: name, key: key, value: $0)
                }
            }
            .map(on:DispatchQueue.global(qos: .userInitiated)) { item  -> Int in
              
              guard let item = item else { return processed }
                // TODO Fix : Bring price from tx /WETH
                // print("log=",tokenId,log.transactionHash?.hex())
              response(progress,item)
              return processed + 1
            }
            .recover { error -> Promise<Int> in
              print(error)
              return Promise.value(processed)
            }
        })
      }
    }
  }
  
  func refreshLatestEvents(onDone: @escaping () -> Void, _ response: @escaping (LoadingProgress,FeedItem) -> Void) {
    var prev : Promise<Void> = Promise.value(())
    
    print("refreshLatestEvents")
    self.logsFetcher.updateLatest(onDone: {
      print("onDone")
      prev.done { onDone() }.catch { print($0); onDone() }
    }) { (progress,log) in
      prev = prev.then { () -> Promise<Void> in
        
        guard let blockNumber = log.blockNumber else { return Promise.value(()) }
        
        // Use the node hash to get the value, as it is not in the event
        let res = try! web3.eth.abi.decodeLog(event:self.TextChanged,from:log);
        let key = res["key"] as! String
        let namehash = SolidityWrappedValue.fixedBytes(res["node"] as! Data)
        return ENSCached.avatarOwnerOfNamehash(SolidityWrappedValue.fixedBytes(res["node"] as! Data), block: blockNumber.quantity,eth:web3.eth)
          .then(on:DispatchQueue.global(qos: .userInitiated)) { (address,avatar) -> Promise<(NFTItem?,EthereumAddress?,String?)> in
            guard let avatar = avatar else { return Promise.value((nil,address,nil)) }
            return ENSTextChangedFeed.parseENSAvatar(avatar: avatar).map { ($0,address) }
              .then(on:DispatchQueue.global(qos: .userInitiated)) { info -> Promise<(NFTItem?,EthereumAddress?,String?)> in
                let (item,address) = info
                guard let _ = item else { return Promise.value((nil,address,nil)) }
                guard let address = address else { return Promise.value((nil,address,nil)) }
                return ENSCached.nameOfOwner(address, eth: web3.eth)
                  .map { (item,address,$0) }
              }
          }
          .then(on:DispatchQueue.global(qos: .userInitiated)) { info -> Promise<FeedItem?> in
            
            let (nftItem,address,name) = info
            guard let address = address else { return Promise.value(nil) }
            guard let nftItem = nftItem else { return Promise.value(nil) }
            
            return ENSWrapper.shared.textOfName(namehash: namehash, key: key, block: blockNumber.quantity)
              .map {
                FeedItem(nft: nftItem, blockNumber: blockNumber, address: address, ensName: name, key: key, value: $0)
              }
          }
          .map(on:DispatchQueue.global(qos: .userInitiated)) { item  -> Void in
            
            guard let item = item else { return }
            // TODO Fix : Bring price from tx /WETH
            // print("log=",tokenId,log.transactionHash?.hex())
            response(progress,item)
          }
          .recover { error -> Promise<Void> in
            print(error)
            return Promise.value(())
          }
      }
    }
  }
}
