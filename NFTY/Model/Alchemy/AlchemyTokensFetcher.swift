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
  
  func fetch() -> Promise<[NFTToken]> {
    
    if (self._done) { return Promise.value([]) }
    
    return AlchemyApi.GetNFTs.get(owner: self.owner, pageKey: self._pageKey)
      .then(on:DispatchQueue.global(qos:.userInitiated)) { (result:AlchemyApi.GetNFTs.Result) -> Promise<[NFTToken]> in
        self._pageKey = result.pageKey
        if (result.pageKey == .none) {
          self._done = true
        }
        return reduce_p(result.ownedNfts, [], { accu, ownedNft in
          collectionsFactory.getByAddressOpt(ownedNft.contract.address)
            .map { collection in
              
              guard let collection = collection else { return accu }
              
              guard let tokenId = try? ABI.decodeParameter(type: .uint256, from: ownedNft.id.tokenId) as? BigUInt else {
                print("Could not hex parse \(ownedNft.id.tokenId)")
                return accu
              }
              
              return accu + [
                NFTToken(
                  collection: collection,
                  nft: collection.contract.getToken(UInt(tokenId)))
              ]
            }
        })
      }
  }
}
