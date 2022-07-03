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
    
    let tokenId = (try? BigUInt(tokenIdStr))
    guard let tokenId = tokenId else { print("TokenId not a match \(tokenIdStr)"); return Promise.value(nil) }
    
    return collectionsFactory.getByAddressOpt(address.hex(eip55: true))
      .map  { collectionOpt -> NFTItem? in
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
  
  let action : Action.ActionType
  
  private func actionOfLog(ethAddress:EthereumAddress) -> Action {
    switch(self.action) {
    case .sold:
      return Action(account: UserAccount(ethAddress:ethAddress, nearAccount: nil),action:.sold)
    case .bought:
      return Action(account: UserAccount(ethAddress:ethAddress, nearAccount: nil),action:.bought)
    case .minted:
      return Action(account: UserAccount(ethAddress:ethAddress, nearAccount: nil),action:.minted)
    }
  }
  
  init(fromBlock:BigUInt,limit:Int) {
    let cacheId = "ENSTextChangedFeed.initFromBlock"
    let blockDecrements = BigUInt(1500)
    self.limit = limit
    self.retries = 10
    self.action = .minted
    self.logsFetcher = LogsFetcher(
      event: self.TextChanged,
      fromBlock: fromBlock - blockDecrements,
      address: nil,
      cacheId : cacheId,
      topics: [
        EthereumGetLogTopics.and(nil),
        EthereumGetLogTopics.and(try! ABI.encodeParameter(SolidityWrappedValue.string("avatar")))
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
    },onRetry:onRetry,limit:self.limit,retries:self.retries) { progress,log in
      let p = processed.then { processed -> Promise<Int> in
        
        // Use the node hash to get the value, as it is not in the event
        guard let removed = log.removed else { return Promise.value(processed) }
        if (removed) { return Promise.value(processed) }
        // guard let transactionHash = log.transactionHash else { return Promise.value(processed) }
        
        let res = try! web3.eth.abi.decodeLog(event:self.TextChanged,from:log);
        return ENSContract.avatarOfNamehash(SolidityWrappedValue.fixedBytes(res["node"] as! Data),eth:web3.eth)
          .then { avatar -> Promise<NFTItem?> in
            guard let avatar = avatar else { return Promise.value(nil) }
            return ENSTextChangedFeed.parseENSAvatar(avatar: avatar)
          }
          .map  { nftItem -> Int in
            
            guard let nftItem = nftItem else { return processed }
            
            // TODO Fix : Bring price from tx /WETH
            // print("log=",tokenId,log.transactionHash?.hex())
            response(progress,nftItem)
            return processed + 1
          }
          .recover { error -> Promise<Int> in
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
        
        // Use the node hash to get the value, as it is not in the event
        let res = try! web3.eth.abi.decodeLog(event:self.TextChanged,from:log);
        return ENSContract.avatarOfNamehash(SolidityWrappedValue.fixedBytes(res["node"] as! Data),eth:web3.eth)
          .then { avatar -> Promise<NFTItem?> in
            guard let avatar = avatar else { return Promise.value(nil) }
            return ENSTextChangedFeed.parseENSAvatar(avatar: avatar)
          }
          .map  { nftItem -> Void in
            
            guard let nftItem = nftItem else { return }
            
            // TODO Fix : Bring price from tx /WETH
            // print("log=",tokenId,log.transactionHash?.hex())
            response(progress,nftItem)
          }
          .recover { error -> Promise<Void> in
            print(error)
            return Promise.value(())
          }
      }
      prev = p
    }
  }
}
