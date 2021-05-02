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
  
  func getRecentTrades(currentIndex:Int?) {}
}

class CryptoPunksTrades : NftRecentTradesObject {
    
  var contract : ContractInterface = CryptoPunksContract()
  private var isLoading = false
  
  private func loadMore() {
    guard !isLoading else {
      return
    }
    contract.getRecentTrades(onDone:{self.isLoading = false}) { nft in
      DispatchQueue.main.async {
        self.recentTrades.append(nft)
      }
    }
  }
  
  override func getRecentTrades(currentIndex:Int?) {
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

class CryptoKittiesTrades : NftRecentTradesObject,HasContractInterface {
  
  var contract : ContractInterface = CryptoKittiesAuction()
  
  private var isLoading = false
  
  private func loadMore() {
    guard !isLoading else {
      return
    }
    contract.getRecentTrades(onDone:{self.isLoading = false}) { nft in
      DispatchQueue.main.async {
        self.recentTrades.append(nft)
      }
    }
  }
  
  override func getRecentTrades(currentIndex:Int?) {
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

class AsciiPunksTrades : NftRecentTradesObject {
  
  var contract : ContractInterface = AsciiPunksContract()
  private var isLoading = false
  
  private func loadMore() {
    guard !isLoading else {
      return
    }
    contract.getRecentTrades(onDone:{self.isLoading = false}) { nft in
      DispatchQueue.main.async {
        self.recentTrades.append(nft)
      }
    }
  }
  
  override func getRecentTrades(currentIndex:Int?) {
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
