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
   
  private var web3 : Web3
  private var contractAddress : EthereumAddress
  private var contractJsonABI : Data
  var contract : GenericERC721Contract
  
  override init() {
    web3 = Web3(rpcURL: "https://mainnet.infura.io/b4287cfd0a6b4849bd0ca79e144d3921")
    contractAddress = try! EthereumAddress(hex: "0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb", eip55: false)
    contractJsonABI = loadData("CryptoPunksAbi.json");
    print(String(decoding: contractJsonABI, as: UTF8.self));
    contract = web3.eth.Contract(type:GenericERC721Contract.self, address: contractAddress);
  }
  
  override func getRecentTrades() {
    print("Called getRecentTrades");
    // Get balance of some address
    firstly {
      try! contract.balanceOf(address:EthereumAddress(hex: "0xf4b4a58974524e183c275f3c6ea895bc2368e738", eip55: false)).call()
    }.done { outputs in
      print(outputs);
      self.recentTrades = CryptoPunksNfts
    }.catch {
      print($0);
      self.recentTrades = CryptoPunksNfts
    }
    
  }
}

class CryptoKittiesTrades : NftRecentTradesObject {
  
  private var web3 : Web3
  private var contractAddress : EthereumAddress
  private var contractJsonABI : Data
  var contract : GenericERC721Contract
  
  override init() {
    web3 = Web3(rpcURL: "https://mainnet.infura.io/b4287cfd0a6b4849bd0ca79e144d3921")
    contractAddress = try! EthereumAddress(hex: "0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb", eip55: false)
    contractJsonABI = loadData("CryptoPunksAbi.json");
    print(String(decoding: contractJsonABI, as: UTF8.self));
    contract = web3.eth.Contract(type:GenericERC721Contract.self, address: contractAddress);
  }
  
  override func getRecentTrades() {
    print("Called getRecentTrades");
    // Get balance of some address
    firstly {
      try! contract.balanceOf(address:EthereumAddress(hex: "0xf4b4a58974524e183c275f3c6ea895bc2368e738", eip55: false)).call()
    }.done { outputs in
      print(outputs);
      self.recentTrades = CryptoKittiesNfts
    }.catch {
      print($0);
      self.recentTrades = CryptoKittiesNfts
    }
    
  }
}
