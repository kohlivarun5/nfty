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
  var contract : ContractInterface
  private var parentOnTrade : (NFTWithPrice) -> Void
  
  init(contract:ContractInterface,parentOnTrade : @escaping (NFTWithPrice) -> Void) {
    self.contract = contract
    self.parentOnTrade = parentOnTrade
  }
  
  func loadMore(_ callback : @escaping () -> Void) {
    guard !isLoading else {
      return
    }
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
  
  private func onTrade(_ nft:NFTWithPrice) -> Void {
    return recentTrades.append(NFTWithPriceAndInfo(nftWithPrice:nft,info:punks.info))
  }
  
  init(punks:CollectionInitializer,kitties:CollectionInitializer,ascii:CollectionInitializer) {
    weak var selfWorkaround: CompositeRecentTradesObject?
    
    self.punks = Collection(
      info:punks.info,
      data:CollectionData(
        recentTrades:NftRecentTradesObject(contract:punks.contract) { nft in
          DispatchQueue.main.async {
            selfWorkaround!.recentTrades.append(NFTWithPriceAndInfo(nftWithPrice:nft,info:selfWorkaround!.punks.info))
          }
        },
        contract:punks.contract))
    
    self.kitties = Collection(
      info:kitties.info,
      data:CollectionData(
        recentTrades:NftRecentTradesObject(contract:kitties.contract) { nft in
          DispatchQueue.main.async {
            selfWorkaround!.recentTrades.append(NFTWithPriceAndInfo(nftWithPrice:nft,info:selfWorkaround!.kitties.info))
          }
        },
        contract:kitties.contract))
    
    self.ascii = Collection(
      info:ascii.info,
      data:CollectionData(
        recentTrades:NftRecentTradesObject(contract:ascii.contract) { nft in
          DispatchQueue.main.async {
            selfWorkaround!.recentTrades.append(NFTWithPriceAndInfo(nftWithPrice:nft,info:selfWorkaround!.ascii.info))
          }
        },
        contract:ascii.contract))
    selfWorkaround = self
  }
  
  private func loadMore() {
    if (pendingCounter > 0) {
      return
    }
    
    pendingCounter = 3
    self.punks.data.recentTrades.loadMore() {
      DispatchQueue.main.async {
        self.pendingCounter+=1
      }
    }
    
    self.kitties.data.recentTrades.loadMore() {
      DispatchQueue.main.async {
        self.pendingCounter+=1
      }
    }
    
    self.ascii.data.recentTrades.loadMore() {
      DispatchQueue.main.async {
        self.pendingCounter+=1
      }
    }
  }
  
  func getRecentTrades(currentIndex:Int?) {
    // print("getRecentTrades currentIndex=\(currentIndex) total=\(self.recentTrades.count) isLoading=\(self.isLoading)");
    guard let index = currentIndex else {
      loadMore()
      return
    }
    
    let thresholdIndex = self.recentTrades.index(self.recentTrades.endIndex, offsetBy: -20)
    if index >= thresholdIndex {
      loadMore()
    }
  }
}
