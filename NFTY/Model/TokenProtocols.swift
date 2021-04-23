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

class NftRecentTradesObject : ObservableObject {
  
  @Published var recentTrades: [NFT] = []
  var recentTradesPublished: Published<[NFT]> { _recentTrades }
  var recentTradesPublisher: Published<[NFT]>.Publisher { $recentTrades }
  
  func getRecentTrades() {}
}

class CryptoPunksTrades : NftRecentTradesObject {
    
  private var contract = CryptoPunksContract()
  
  override func getRecentTrades() {
    contract.getRecentTrades() { nft in
      self.recentTrades.append(nft)
    }
  }
}

class CryptoKittiesTrades : NftRecentTradesObject {
  
  private var contract = CryptoKittiesAuction()
  
  override func getRecentTrades() {
    contract.getRecentTrades() { nft in
      self.recentTrades.append(nft)
    }
  }
}
