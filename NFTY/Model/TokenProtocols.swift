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
  
  var collections : [Collection]
  
  private var pendingCounter = 0
  private var pendingCounterLatest = 0
  
  init(_ collections:[CollectionInitializer]) {
    weak var selfWorkaround: CompositeRecentTradesObject?
    
    self.collections = collections.map { initializer in
      return Collection(
        info:initializer.info,
        data:CollectionData(
          recentTrades:NftRecentTradesObject(contract:initializer.contract,parentOnTrade: { nft in
            DispatchQueue.main.async {
              if (!initializer.info.disableRecentTrades) {
                selfWorkaround!.recentTrades.append(NFTWithPriceAndInfo(nftWithPrice:nft,info:initializer.info))
              }
            }
          },parentOnLatest: { nft in
            DispatchQueue.main.async {
              if (!initializer.info.disableRecentTrades) {
                selfWorkaround!.recentTrades.insert(NFTWithPriceAndInfo(nftWithPrice:nft,info:initializer.info),at:0)
              }
            }
          }),
          contract:initializer.contract))
    }
    selfWorkaround = self
  }
  
  func loadMore(_ onDone : @escaping () -> Void) {
    if (pendingCounter > 0) {
      return
    }
    
    pendingCounter = 0
    self.collections.forEach { collection in
      if (!collection.info.disableRecentTrades) {
        pendingCounter += 1
        collection.data.recentTrades.loadMore() {
          DispatchQueue.main.async {
            self.pendingCounter-=1
            if (self.pendingCounter == 0) { onDone() }
          }
        }
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
    
    pendingCounter = 0
    self.collections.forEach { collection in
      if (!collection.info.disableRecentTrades) {
        pendingCounter += 1
        collection.data.recentTrades.loadLatest() {
          DispatchQueue.main.async {
            self.pendingCounterLatest-=1
            if (self.pendingCounterLatest < 2) {
              onDone()
            }
          }
        }
      }
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
    print("Calling getEvents")
    fetcher.getEvents(
      onDone:{
        self.isLoading = false;
        // print(self.events.count)
        callback();
      }) { event in
      DispatchQueue.main.async {
        self.events.append(event)
        self.events.sort { left, right in
          return left.blockNumber.quantity > right.blockNumber.quantity
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
