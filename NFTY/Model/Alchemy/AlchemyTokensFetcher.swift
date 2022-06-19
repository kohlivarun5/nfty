//
//  AlchemyTokensFetcher.swift
//  NFTY
//
//  Created by Varun Kohli on 6/13/22.
//

import Foundation
import Web3
import PromiseKit
import Web3
import Web3ContractABI

class AlchemyTokensFetcher {
  
  private var _pageKey : String?
  private var _done : Bool = false
  
  let owner : EthereumAddress
  
  init(owner:EthereumAddress) {
    self.owner = owner
  }
  
  func done() -> Bool { return self._done }
  
  func fetch(onTokens: @escaping (_ tokens:[NFTToken]) -> Void) -> Promise<Void> {
    
    if (self._done) {
      print("Alchemy Fetch called but tokens done")
      return Promise.value(())
    }
    
    return AlchemyApi.GetNFTs.get(owner: self.owner, pageKey: self._pageKey)
      .then(on:DispatchQueue.global(qos:.userInitiated)) { (result:AlchemyApi.GetNFTs.Result) -> Promise<Void> in
        print("Alchemy returned with count=\(result.totalCount),\(result.ownedNfts.count), pageKey=\(result.pageKey ?? "None")")
        self._pageKey = result.pageKey
        if (result.pageKey == .none) {
          self._done = true
        }
        
        let groupDict = Dictionary(grouping: result.ownedNfts, by: { $0.contract.address })
        
        return reduce_p(groupDict.map { ($0.key,$0.value) }, (), { _, collection_tokens in
          let (collection_address,tokens) = collection_tokens
          return collectionsFactory.getByAddressOpt(collection_address)
            .map(on:.global(qos: .userInitiated)) { collection -> Void in
              guard let collection = collection else { return () }
              
              let nfts = tokens.compactMap { ownedNft -> NFTToken? in
                
                guard let tokenId = try? ABI.decodeParameter(type: .uint256, from: ownedNft.id.tokenId) as? BigUInt else {
                  print("Could not hex parse \(ownedNft.id.tokenId)")
                  return nil
                }
                
                if (tokenId.bitWidth > UInt.bitWidth) {
                  print("Could fit in Uint \(ownedNft.id.tokenId)")
                  return nil
                }
                
                return NFTToken(
                  collection: collection,
                  nft: collection.contract.getToken(UInt(tokenId)))
              }
              return onTokens(nfts)
            }
        })
      }
  }
}
