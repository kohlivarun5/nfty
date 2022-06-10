//
//  OwnerTokens.swift
//  NFTY
//
//  Created by Varun Kohli on 2/26/22.
//

import Foundation
import PromiseKit
import CloudKit
import Web3

class NftOwnerTokens : ObservableObject,Identifiable {
  
  @Published var tokens: [(Collection,[NFTToken])] = []
  var foundMax = false
  
  private var openSeaOffset : UInt = 0
  private var parasOffset : UInt = 0
  
  private var ckLoader : CKOwnerTokensFetcher.Loader?
  
  private let limit : UInt = 10
  private var loadedFromChain = false
  
  enum LoadingState {
    case notLoaded
    case loading
    case loaded
    case loadingMore
  }
  @Published var state : LoadingState = .notLoaded
  
  let account : UserAccount
  private let database : CKDatabase
  
  private var pendingCount = 0
  
  init(account:UserAccount) {
    self.account = account
    let database = CKContainer.default().publicCloudDatabase
    self.database = database
    self.ckLoader = self.account.ethAddress.map {
      CKOwnerTokensFetcher.Loader(
        database: database,
        owner: $0)
    }
  }
  
  private func openseaTokens(address:EthereumAddress) -> Promise<[NFTToken]> {
    
    return OpenSeaApi.getOwnerTokens(address: address,offset:self.openSeaOffset,limit:limit)
      .recover { error -> Promise<[NFTToken]> in
        print("OpenSea Error=\(error)")
        self.foundMax = true
        return Promise.value([])
      }.then { openSeaTokens -> Promise<[NFTToken]> in
        // Open sea errored, lets recover from known collections
        if (self.loadedFromChain) {
          return Promise.value(openSeaTokens)
        } else {
          self.loadedFromChain = true
          return collectionsFactory.getAll()
            .reduce(Promise<[NFTToken]>.value(openSeaTokens), { accu,collection in
              if (collection.info.disableRecentTrades) {
                return accu
              }
              return after(seconds: 0.2).then { _ in
                accu.then { accuTokens -> Promise<[NFTToken]> in
                  if (accuTokens.contains { $0.collection.contract.contractAddressHex == collection.contract.contractAddressHex}) {
                    return Promise.value(accuTokens)
                  }
                  return Promise { seal in
                    var tokens : [NFTWithLazyPrice] = []
                    collection.contract.getOwnerTokens(
                      address: address,
                      onDone: {
                        seal.fulfill(tokens.map { NFTToken(collection: collection, nft: $0) } + accuTokens)
                      },
                      { token in
                        if (!accuTokens.contains { $0.id == token.id }) {
                          tokens.append(token)
                        }
                      })
                  }
                }
              }
            })
        }
      }
  }
  
  func refreshTokensFromOpensea() -> Promise<Void> {
    
    switch self.account.ethAddress {
    case .none:
      return Promise.value(())
    case .some(let address):
      return after(seconds:1).then {
        self.openseaTokens(address: address)
          .then { (tokens:[NFTToken]) -> Promise<Void> in
            CKOwnerTokensFetcher.saveOwnerTokens(
              database: self.database,
              owner: address,
              tokens: tokens)
            
            if (tokens.isEmpty) {
              return Promise.value(())
            } else {
              self.openSeaOffset = self.openSeaOffset + self.limit
              return self.refreshTokensFromOpensea()
            }
          }
      }
    }
  }
  
  func load(_ onDone: @escaping () -> Void) {
    print("State=\(state)")
    if (state == .loading || state == .loadingMore || foundMax) { return onDone() }
    
    if (self.state == .notLoaded) {
      self.refreshTokensFromOpensea()
        .catch { print($0) }
    }
    
    self.state = self.state == .notLoaded ? .loading : .loadingMore
    
    DispatchQueue.main.async {
      self.ckLoader?.fetch()
        .then { results -> Promise<[NFTToken]> in
          print("CK results=\(results)")
          var tokens : [NFTToken] = []
          results.forEach { (_,list) in tokens.append(contentsOf: list) }
          
          switch(self.account.nearAccount) {
          case .none:
            return Promise.value(tokens)
          case .some(let nearAddress):
            return ParasApi.token(owner_id: nearAddress, offset: self.parasOffset, limit: self.limit)
              .map { (results:ParasApi.Token) -> [NFTToken] in
                results.data.results.compactMap { token -> NFTToken? in
                  guard let tokenId = UInt(token.token_id) else { return nil }
                  let collection = NearCollection(address:token.contract_id)
                  return NFTToken(
                    collection:collection,
                    nft: collection.contract.getToken(tokenId))
                } + tokens
              }.recover { error -> Promise<[NFTToken]> in
                print("Pras failed with \(error)");
                return Promise.value(tokens)
              }
          }
        }
        .done(on:.main) {
          
          print("Found tokens count=\($0.count)")
          
          self.foundMax = self.foundMax || $0.isEmpty
          
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
        .catch { print("Failed to fetch owner tokens\($0)") }
        .finally(on:.main) {
          self.state = .loaded
          print("State=\(self.state)")
          self.parasOffset = self.parasOffset + self.limit
          onDone()
        }
      
    }
  }
  
  func loadMore(_ index:Int) {
    if (index > (self.tokens.count - 3)) {
      DispatchQueue.main.async { self.load({}) }
    }
  }
  
}

var OwnerTokensCache : [String:NftOwnerTokens] = [:]
func getOwnerTokens(_ account:UserAccount) -> NftOwnerTokens {
  switch (account.ethAddress.flatMap { OwnerTokensCache[$0.hex(eip55: true)] },account.nearAccount.flatMap { OwnerTokensCache[$0] }) {
    /* case (.some(let tokens),_),(_,.some(let tokens)):
     return tokens
     case (.none,.none):*/ default:
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
