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
  
  func getRecentTrades(currentIndex:Int?,_ callback : @escaping () -> Void) {
    guard let index = currentIndex else {
      loadMore(callback)
      return
    }
    let thresholdIndex = self.recentTrades.index(self.recentTrades.endIndex, offsetBy: -5)
    if index >= thresholdIndex {
      loadMore(callback)
    } else {
      callback()
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
  
  struct NFTItem {
    let nft : NFTWithPriceAndInfo
    let collection : Collection
  }
  
  @Published var recentTrades: [NFTItem] = []
  
  @Published var loadMoreState : LoadingState = .uninitialized
  @Published var loadRecentState : LoadingState = .uninitialized
  
  private var loadedItems: [NFTItem] = []
  
  var recentTradesPublished: Published<[NFTItem]> { _recentTrades }
  var recentTradesPublisher: Published<[NFTItem]>.Publisher { $recentTrades }
  
  struct CollectionLoader {
    var collection : Collection
    var recentTrades: NftRecentTradesObject
  }
  
  private func loadPrice(_ trade:NFTWithPriceAndInfo,onDone: @escaping () -> Void) {
    switch(trade.nftWithPrice.indicativePrice) {
    case .lazy(let promise):
      promise().loadMore { onDone() }
    case .eager:
      onDone()
    }
  }
  
  private func preload(list:[NFTItem],index:Int,onDone: @escaping () -> Void) {
    
    switch(list[safe:index]) {
    case .some(let trade):
      switch(trade.nft.nftWithPrice.nft.media) {
      case .asciiPunk(let punk):
        punk.ascii.loadMore { self.loadPrice(trade.nft,onDone: onDone) }
      case .autoglyph(let glyph):
        glyph.autoglyph.loadMore { self.loadPrice(trade.nft,onDone: onDone) }
      case .image(let image):
        image.url.loadMore { self.loadPrice(trade.nft,onDone: onDone) }
      case .ipfsImage(let image):
        image.image.loadMore { self.loadPrice(trade.nft,onDone: onDone) }
      }
    case .none:
      onDone()
    }
    
  }
  
  private func onDone(_ onDone : @escaping () -> Void) {
    if (loadedItems.count == 0) { onDone(); return }
    
    var items = self.recentTrades.map { NFTItem(nft: $0.nft,collection:$0.collection) }
    items.append(contentsOf: self.loadedItems)
    
    self.loadedItems = []
    
    let sorted = items.sorted { left,right in
      switch(left.nft.nftWithPrice.blockNumber,right.nft.nftWithPrice.blockNumber) {
      case (.none,.none):
        return true
      case (.some(let l),.some(let r)):
        return l > r;
      case (.none,.some):
        return true;
      case (.some,.none):
        return false;
      }
    }
    
    self.preload(list:sorted,index: 0, onDone: {
      self.preload(list:sorted,index: 1, onDone: {
        DispatchQueue.main.async {
          self.recentTrades = sorted
          onDone()
        }
      })
    })
    
  }
  
  private let collections : [Collection]
  init(_ collections:[Collection]) {
    self.collections = collections
  }
  
  lazy var loaders : [CollectionLoader] = {
    return collections.map { [weak self] collection in
      return CollectionLoader(
        collection:collection,
        
        recentTrades:NftRecentTradesObject(
          contract:collection.contract,
          parentOnTrade: { nft in
            DispatchQueue.main.async {
              if (!collection.info.disableRecentTrades) {
                self?.loadedItems.append(
                  NFTItem(nft: NFTWithPriceAndInfo(nftWithPrice:nft,info:collection.info),collection:collection)
                )
              }
            }
          },parentOnLatest: { nft in
            DispatchQueue.main.async {
              if (!collection.info.disableRecentTrades) {
                self?.loadedItems.append(
                  NFTItem(nft: NFTWithPriceAndInfo(nftWithPrice:nft,info:collection.info),collection:collection)
                )
              }
            }
          })
      )
    }
  }()
  
  public func getLoader(collection:Collection) -> CollectionLoader {
    switch(self.loaders.first{$0.collection.info.address == collection.info.address}) {
    case .some(let loader):
      return loader
    case .none:
      return CollectionLoader(
        collection:collection,
        recentTrades:NftRecentTradesObject(
          contract:collection.contract,
          parentOnTrade: { _ in return },
          parentOnLatest: {  _ in return })
      )
    }
  }
  
  private func loadMoreIndex(index:Int,onDone : @escaping () -> Void) {
    DispatchQueue.main.async {
      self.loadMoreState = .loading(LoadingProgress(current:index,total:self.loaders.count))
    }
    switch(self.loaders[safe:index]) {
    case .some(let loader):
      if (loader.collection.info.disableRecentTrades) {
        self.loadMoreIndex(index:index+1,onDone:onDone)
      } else {
        loader.recentTrades.loadMore() {
          self.loadMoreIndex(index:index+1,onDone:onDone)
        }
      }
    case .none:
      DispatchQueue.main.async {
        self.loadMoreState = .notLoading
      }
      self.onDone(onDone)
    }
  }
  
  func loadMore(_ onDone : @escaping () -> Void) {
    DispatchQueue.main.async {
      switch(self.loadMoreState) {
      case .loading:
        return
      case .uninitialized,.notLoading:
        self.loadMoreState = .loading(LoadingProgress(current:0,total:self.loaders.count))
      }
      
      self.loadMoreIndex(index: 0,onDone: onDone)
    }
  }
  
  func getRecentTrades(currentIndex:Int?,_ onDone : @escaping () -> Void) {
    guard let index = currentIndex else {
      loadMore(onDone)
      return
    }
    
    let thresholdIndex = self.recentTrades.index(self.recentTrades.endIndex, offsetBy: -5)
    if index >= thresholdIndex {
      loadMore(onDone)
    } else {
      self.preload(list:self.recentTrades,index:index+1,onDone:{
        self.preload(list:self.recentTrades,index:index+2,onDone:onDone)
      })
    }
  }
  
  private func loadLatestIndex(index:Int,onDone : @escaping () -> Void) {
    DispatchQueue.main.async {
      self.loadRecentState = .loading(LoadingProgress(current:index,total:self.loaders.count))
    }
    switch(self.loaders[safe:index]) {
    case .some(let loader):
      if (loader.collection.info.disableRecentTrades) {
        self.loadLatestIndex(index:index+1,onDone:onDone)
      } else {
        loader.recentTrades.loadLatest() {
          self.loadLatestIndex(index:index+1,onDone:onDone)
        }
      }
    case .none:
      DispatchQueue.main.async {
        self.loadRecentState = .notLoading
      }
      self.onDone(onDone)
    }
  }
  
  func loadLatest(_ onDone : @escaping () -> Void) {
    DispatchQueue.main.async {
      switch(self.loadRecentState) {
      case .loading:
        return onDone()
      case .uninitialized,.notLoading:
        self.loadRecentState = .loading(LoadingProgress(current:0,total:self.loaders.count))
      }
      self.loadLatestIndex(index:0,onDone: onDone)
    }
  }
  
}


class NftRecentEventsObject : ObservableObject {
  @Published var events: [TradeEvent] = []
  var eventsPublished: Published<[TradeEvent]> { _events }
  var eventsPublisher: Published<[TradeEvent]>.Publisher { $events }
  
  private var isLoading = false
  var fetcher : TokenEventsFetcher
  
  init(fetcher:TokenEventsFetcher) {
    self.fetcher = fetcher
  }
  
  func loadMore(_ callback : @escaping () -> Void) {
    guard !isLoading else { return }
    self.isLoading = true
    fetcher.getEvents(
      onDone:{
        self.isLoading = false;
        // print(self.events.count)
        callback();
      }) { event in
        DispatchQueue.main.async {
          self.events.append(event)
          self.events.sort { left, right in
            return left.blockNumber > right.blockNumber
          }
        }
      }
  }
  
  func getEvents(currentIndex:Int?) {
    guard let index = currentIndex else {
      loadMore() {}
      return
    }
    let thresholdIndex = self.events.index(self.events.endIndex, offsetBy: -5)
    if index >= thresholdIndex {
      loadMore() {}
    }
  }
}

class NftTokenList : ObservableObject {
  @Published var tokens: [NFTWithLazyPrice] = []
  var eventsPublished: Published<[NFTWithLazyPrice]> { _tokens }
  var eventsPublisher: Published<[NFTWithLazyPrice]>.Publisher { $tokens }
  
  private let loadingChunk = 20
  private var isLoading = false
  let contract : ContractInterface
  let tokenIds : [UInt]
  
  init(contract:ContractInterface,tokenIds:[UInt]) {
    self.contract = contract
    self.tokenIds = tokenIds
  }
  
  func loadMore(_ callback : @escaping () -> Void) {
    guard !isLoading else { return }
    self.isLoading = true
    
    let before = tokens.count
    
    var index = tokens.count
    while(index < tokenIds.count && index < (before + loadingChunk)) {
      let tokenId = tokenIds[index]
      let nft = contract.getToken(tokenId)
      DispatchQueue.main.async {
        self.tokens.append(nft)
      }
      index+=1
    }
    
    self.isLoading = false
  }
  
  func next(currentIndex:Int?) {
    guard let index = currentIndex else {
      loadMore() {}
      return
    }
    let thresholdIndex = self.tokens.index(self.tokens.endIndex, offsetBy: -5)
    if index >= thresholdIndex {
      loadMore() {}
    }
  }
}
