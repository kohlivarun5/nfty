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
class NftRecentTradesObject : ObservableObject {
  
  @Published var recentTrades: [NFT] = []
  var recentTradesPublished: Published<[NFT]> { _recentTrades }
  var recentTradesPublisher: Published<[NFT]>.Publisher { $recentTrades }
  
  func getRecentTrades(currentIndex:Int?) {}
}

class CryptoPunksTrades : NftRecentTradesObject {
    
  private var contract = CryptoPunksContract()
  private var isLoading = false
  
  private func loadMore() {
    guard !isLoading else {
      return
    }
    contract.getRecentTrades() { (nft,isFinal) in
      self.isLoading = !isFinal
      DispatchQueue.main.async {
        self.recentTrades.append(nft)
      }
    }
  }
  
  override func getRecentTrades(currentIndex:Int?) {
    print("getRecentTrades currentIndex=\(currentIndex) total=\(self.recentTrades.count) isLoading=\(self.isLoading)");
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

class CryptoKittiesTrades : NftRecentTradesObject {
  
  private var contract = CryptoKittiesAuction()
  
  override func getRecentTrades(currentIndex:Int?) {
    contract.getRecentTrades() { nft in
      self.recentTrades.append(nft)
    }
  }
}
