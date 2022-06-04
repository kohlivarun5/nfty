//
//  OwnerTokens.swift
//  NFTY
//
//  Created by Varun Kohli on 2/26/22.
//

import Foundation
import PromiseKit
import Web3

class OwnerCollections {
  
  static func knownCollections(owner:String) -> Promise<[Collection]> {
    let key = CloudDefaultStorageKeys.knownOwnerCollections.rawValue + "."+owner
    let addresses = NSUbiquitousKeyValueStore.default.object(forKey: key) as? [String] ?? []
    return reduce_p(addresses,[], { accu,addr -> Promise<[Collection]> in
      return MakeErc721Collection.ofAddress(address: try! EthereumAddress(hex:addr,eip55: false))
        .then { (coll:Collection?) -> Promise<[Collection]> in
          switch (coll) {
          case .none:
            return Promise.value(accu)
          case .some(let coll):
            return Promise.value(accu + [coll])
          }
        }
    })
  }
  
  private static func saveKnownCollections(owner:String,addresses:[String]) {
    print("Saving collections = \(addresses)")
    let key = CloudDefaultStorageKeys.knownOwnerCollections.rawValue + "."+owner
    NSUbiquitousKeyValueStore.default.set(addresses,forKey:key)
  }
  
  static func updateKnwonFromOpenSea(account:UserAccount) {
    switch(account.ethAddress) {
    case .none:
      return
    case .some(let address):
      OpenSeaApi.collections(owner:address)
        .done {
          saveKnownCollections(owner:address.hex(eip55: true),addresses:$0)
        }.catch { print($0) }
      
    }
  }
}

class NftOwnerTokens : ObservableObject,Identifiable {
  
  @Published var tokens: [(Collection,[NFTToken])] = []
  var foundMax = false
  
  private var openSeaOffset : UInt = 0
  private var parasOffset : UInt = 0
  
  private let limit : UInt = 10
  private var updatedCache = false
  
  enum LoadingState {
    case notLoaded
    case loading
    case loaded
    case loadingMore
  }
  @Published var state : LoadingState = .notLoaded
  
  let account : UserAccount
  
  private let knownCollections : Promise<[Collection]>
  
  private var pendingCount = 0
  private var collectionIndex = 0
  private var tokenIndex = 0
  
  init(account:UserAccount) {
    self.account = account
    switch(self.account.ethAddress) {
    case .none:
      self.knownCollections = Promise.value([])
    case .some(let owner):
      self.knownCollections = OwnerCollections.knownCollections(owner:owner.hex(eip55: true))
    }
  }
  
  private func knownCollectionTokens() -> Promise<[NFTToken]> {
    switch(self.account.ethAddress) {
    case .none:
      return Promise.value([])
    case .some(let address):
      
      return Promise { seal in
        
        var nfts : [NFTToken] = []
        
        self.knownCollections
          .map { (collections:[Collection]) -> [Collection] in
            print("knownCollections.count = \(collections.count)")
            if (collections.count == 0) { return COLLECTIONS }
            else { return collections }
          }
          .done { (collections:[Collection]) in
            print("collectionIndex = \(self.collectionIndex),collections=\(collections.count)")
            if (collections.count <= self.collectionIndex) {
              return
            }
            
            let collection = collections[self.collectionIndex]
            collection.contract.getOwnerTokens(address: address, onDone: {
              DispatchQueue.main.async {
                print("Advancing, with count=\(nfts.count), for address=\(address.hex(eip55: true))")
                self.collectionIndex = self.collectionIndex + 1
                if (nfts.count <= 0) {
                  self.knownCollectionTokens()
                    .done {
                      seal.fulfill($0)
                    }
                } else {
                  seal.fulfill(nfts)
                }
              }
            }, {(nftWithPrice:NFTWithLazyPrice) in
              DispatchQueue.global(qos:.userInteractive).async {
                nfts.append(NFTToken(collection: collection, nft: nftWithPrice))
              }
            })
          }
      }
    }
  }
  
  func load(_ onDone: @escaping () -> Void) {
    if (state == .loading || state == .loadingMore || foundMax) { return onDone() }
    
    self.state = self.state == .notLoaded ? .loading : .loadingMore
    
    DispatchQueue.main.async {
      
      if (!self.updatedCache) { OwnerCollections.updateKnwonFromOpenSea(account: self.account) }
      self.updatedCache = true
      
      self.knownCollectionTokens()
        .then { openSeaTokens -> Promise<[NFTToken]> in
          switch(self.account.nearAccount) {
          case .none:
            return Promise.value(openSeaTokens)
          case .some(let nearAddress):
            return ParasApi.token(owner_id: nearAddress, offset: self.parasOffset, limit: self.limit)
              .map { (results:ParasApi.Token) -> [NFTToken] in
                results.data.results.compactMap { token -> NFTToken? in
                  guard let tokenId = UInt(token.token_id) else { return nil }
                  let collection = NearCollection(address:token.contract_id)
                  return NFTToken(
                    collection:collection,
                    nft: collection.contract.getToken(tokenId))
                } + openSeaTokens
              }
          }
        }
        .done(on:.main) {
          
          print("Found tokens count=\($0.count)")
          
          // self.foundMax = self.foundMax || $0.isEmpty
          
          $0.forEach { token in
            
            switch(self.tokens.firstIndex { $0.0.info.address == token.collection.info.address }) {
            case .some(let index):
              if (!self.tokens[index].1.contains { $0.id == token.id}) {
                self.tokens[index].1.append(token)
              }
            case .none:
              self.tokens.append((token.collection,[token]))
            }
          }
        }
        .catch { print($0) }
        .finally(on:.main) {
          self.state = .loaded
          self.openSeaOffset = self.openSeaOffset + self.limit
          self.parasOffset = self.parasOffset + self.limit
          onDone()
        }
      
    }
  }
  
  func loadMore(_ index:Int) {
    print("loadMore index=\(index)")
    if (index > (self.tokens.count - 3)) {
      DispatchQueue.main.async { self.load({}) }
    }
  }
  
}

var OwnerTokensCache : [String:NftOwnerTokens] = [:]
func getOwnerTokens(_ account:UserAccount) -> NftOwnerTokens {
  switch (account.ethAddress.flatMap { OwnerTokensCache[$0.hex(eip55: true)] },account.nearAccount.flatMap { OwnerTokensCache[$0] }) {
  case (.some(let tokens),_),(_,.some(let tokens)):
    return tokens
  case (.none,.none):
    let tokens = NftOwnerTokens(account:account)
    switch(account.ethAddress,account.nearAccount) {
    case (.some(let ethAddress),.some(let nearAccount)):
      OwnerTokensCache[ethAddress.hex(eip55: true)] = tokens
      OwnerTokensCache[nearAccount] = tokens
      return tokens
      
    case (.none,.some(let nearAccount)):
      OwnerTokensCache[nearAccount] = tokens
      return tokens
      
    case (.some(let ethAddress),.none):
      OwnerTokensCache[ethAddress.hex(eip55: true)] = tokens
      return tokens
      
    case (.none,.none):
      return tokens
    }
  }
}
