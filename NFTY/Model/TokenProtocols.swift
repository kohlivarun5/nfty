//
//  TokenProtocols.swift
//  NFTY
//
//  Created by Varun Kohli on 4/21/21.
//

import Foundation

import Web3
import Web3PromiseKit
import Web3ContractABI

// https://www.donnywals.com/implementing-an-infinite-scrolling-list-with-swiftui-and-combine/

protocol HasContractInterface {
  var contract : ContractInterface { get }
}

class NftRecentTradesObject : ObservableObject {
  @Published var recentTrades: [NFTWithPrice] = []
  var recentTradesPublished: Published<[NFTWithPrice]> { _recentTrades }
  var recentTradesPublisher: Published<[NFTWithPrice]>.Publisher { $recentTrades }
  
  private var isLoading = false
  private var isLoadingLatest = false
  var contract : ContractInterface
  private var parentOnTrade : (NFTWithPrice) -> Void
  private var parentOnLatest : (NFTWithPrice) -> Void
  
  init(contract:ContractInterface,parentOnTrade : @escaping (NFTWithPrice) -> Void,parentOnLatest : @escaping (NFTWithPrice) -> Void) {
    self.contract = contract
    self.parentOnTrade = parentOnTrade
    self.parentOnLatest = parentOnLatest
  }
  
  func loadMore(_ callback : @escaping () -> Void) {
    guard !isLoading else {
      return
    }
    self.isLoading = true
    contract.getRecentTrades(
      onDone:{
        self.isLoading = false;
        callback();
    }) { nft in
      DispatchQueue.main.async {
        self.recentTrades.append(nft)
        self.parentOnTrade(nft)
      }
    }
  }
  
  func getRecentTrades(currentIndex:Int?) {
    guard let index = currentIndex else {
      loadMore() {}
      return
    }
    let thresholdIndex = self.recentTrades.index(self.recentTrades.endIndex, offsetBy: -20)
    if index >= thresholdIndex {
      loadMore() {}
    }
  }
  
  func loadLatest(_ callback : @escaping () -> Void) {
    guard !isLoadingLatest else {
      return
    }
    self.isLoadingLatest = true;
    contract.refreshLatestTrades(
      onDone:{
        self.isLoadingLatest = false;
        callback();
      }) { nft in
      DispatchQueue.main.async {
        self.recentTrades.insert(nft,at:0)
        self.parentOnLatest(nft)
      }
    }
  }
  
}

class CompositeRecentTradesObject : ObservableObject {
  @Published var recentTrades: [NFTWithPriceAndInfo] = []
  var recentTradesPublished: Published<[NFTWithPriceAndInfo]> { _recentTrades }
  var recentTradesPublisher: Published<[NFTWithPriceAndInfo]>.Publisher { $recentTrades }
  
  struct CollectionInitializer {
    var info : CollectionInfo
    var contract : ContractInterface
  }
  
  var punks : Collection
  var kitties : Collection
  var ascii : Collection
  
  private var pendingCounter = 0
  private var pendingCounterLatest = 0
  
  init(punks:CollectionInitializer,kitties:CollectionInitializer,ascii:CollectionInitializer) {
    weak var selfWorkaround: CompositeRecentTradesObject?
    
    self.punks = Collection(
      info:punks.info,
      data:CollectionData(
        recentTrades:NftRecentTradesObject(contract:punks.contract,parentOnTrade: { nft in
          DispatchQueue.main.async {
            selfWorkaround!.recentTrades.append(NFTWithPriceAndInfo(nftWithPrice:nft,info:selfWorkaround!.punks.info))
          }
        },parentOnLatest: { nft in
          DispatchQueue.main.async {
            selfWorkaround!.recentTrades.insert(NFTWithPriceAndInfo(nftWithPrice:nft,info:selfWorkaround!.punks.info),at:0)
          }
        }),
        contract:punks.contract))
    
    self.kitties = Collection(
      info:kitties.info,
      data:CollectionData(
        recentTrades:NftRecentTradesObject(contract:kitties.contract,parentOnTrade: { nft in
          DispatchQueue.main.async {
            selfWorkaround!.recentTrades.append(NFTWithPriceAndInfo(nftWithPrice:nft,info:selfWorkaround!.kitties.info))
          }
        },parentOnLatest: { nft in
          DispatchQueue.main.async {
            selfWorkaround!.recentTrades.insert(NFTWithPriceAndInfo(nftWithPrice:nft,info:selfWorkaround!.kitties.info),at:0)
          }
        }),
        contract:kitties.contract))
    
    self.ascii = Collection(
      info:ascii.info,
      data:CollectionData(
        recentTrades:NftRecentTradesObject(contract:ascii.contract,parentOnTrade: { nft in
          DispatchQueue.main.async {
            selfWorkaround!.recentTrades.append(NFTWithPriceAndInfo(nftWithPrice:nft,info:selfWorkaround!.ascii.info))
          }
        },parentOnLatest: { nft in
          DispatchQueue.main.async {
            selfWorkaround!.recentTrades.insert(NFTWithPriceAndInfo(nftWithPrice:nft,info:selfWorkaround!.ascii.info),at:0)
          }
        }),
        contract:ascii.contract))
    selfWorkaround = self
  }
  
  func loadMore(_ onDone : @escaping () -> Void) {
    if (pendingCounter > 0) {
      return
    }
    
    pendingCounter = 3
    self.punks.data.recentTrades.loadMore() {
      DispatchQueue.main.async {
        self.pendingCounter-=1
        if (self.pendingCounter == 0) { onDone() }
      }
    }
    
    self.kitties.data.recentTrades.loadMore() {
      DispatchQueue.main.async {
        self.pendingCounter-=1
        if (self.pendingCounter == 0) { onDone() }
      }
    }
    
    self.ascii.data.recentTrades.loadMore() {
      DispatchQueue.main.async {
        self.pendingCounter-=1
        if (self.pendingCounter == 0) { onDone() }
      }
    }
  }
  
  func getRecentTrades(currentIndex:Int?) {
    guard let index = currentIndex else {
      loadMore() {}
      return
    }
    
    let thresholdIndex = self.recentTrades.index(self.recentTrades.endIndex, offsetBy: -20)
    if index >= thresholdIndex {
      loadMore() {}
    }
  }
  
  func loadLatest(_ onDone : @escaping () -> Void) {
    if (pendingCounterLatest > 0) {
      return
    }
    
    pendingCounterLatest = 3
    self.punks.data.recentTrades.loadLatest() {
      DispatchQueue.main.async {
        self.pendingCounterLatest-=1
        onDone()
      }
    }
    
    self.kitties.data.recentTrades.loadLatest() {
      DispatchQueue.main.async {
        self.pendingCounterLatest-=1
        onDone()
      }
    }
    
    self.ascii.data.recentTrades.loadLatest() {
      DispatchQueue.main.async {
        self.pendingCounterLatest-=1
        onDone()
      }
    }
  }
  
}


class NftOwnerTokens : ObservableObject {
  @Published var tokens: [NFTWithLazyPrice] = []
  
  enum LoadingState {
    case notLoaded
    case loading
    case loaded
  }
  @Published var state : LoadingState = .notLoaded
  
  let ownerAddress : EthereumAddress
  private let contracts : [ContractInterface]
  
  private var pendingCount = 0
  
  init(ownerAddress:EthereumAddress) {
    self.ownerAddress = ownerAddress
    self.contracts = [cryptoPunksContract,cryptoKittiesContract,asciiPunksContract]
  }
  
  func load() {
    if (state != .notLoaded) { return }

    state = .loading
    contracts.forEach { contract in
      contract.getOwnerTokens(
        address:ownerAddress,
                              
        onDone: {
          DispatchQueue.main.async {
            self.state = .loaded
          }
        }
      ) { token in
        DispatchQueue.main.async {
          self.tokens.append(token)
        }
      }
    }
  }
  
}
