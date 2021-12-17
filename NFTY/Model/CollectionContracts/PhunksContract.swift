//
//  PhunksContract.swift
//  NFTY
//
//  Created by Varun Kohli on 12/11/21.
//

import Foundation
import Web3
import Web3PromiseKit
import Web3ContractABI

class PhunksContract : ContractInterface {
  
  class EthContract : EthereumContract {
    let eth = web3.eth
    let events : [SolidityEvent] = []
    let addressHex = "0xd6c037bE7FA60587e174db7A6710f7635d2971e7"
    var address : EthereumAddress?
    init() {
      address = try? EthereumAddress(hex:addressHex, eip55: false)
    }
    
    
    func phunksOfferedForSale(_ tokenId:BigUInt) -> Promise<BigUInt?> {
      let inputs = [SolidityFunctionParameter(name: "tokenId", type: .uint256)]
      
      let outputs = [
        SolidityFunctionParameter(name: "isForSale", type: .bool),
        SolidityFunctionParameter(name: "phunkIndex", type: .uint256),
        SolidityFunctionParameter(name: "seller", type: .address),
        SolidityFunctionParameter(name: "minValue", type: .uint256),
        SolidityFunctionParameter(name: "onlySellTo", type: .address)
      ]
      let method = SolidityConstantFunction(name: "phunksOfferedForSale", inputs: inputs, outputs: outputs, handler: self)
      print("calling phunksOfferedForSale")
      return method.invoke(tokenId).call()
        .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs in
          return outputs["isForSale"] as! Bool ? (outputs["minValue"] as? BigUInt).flatMap(priceIfNotZero) : nil
        }
    }
    
    func phunkBids(_ tokenId:BigUInt) -> Promise<BigUInt?> {
      let inputs = [SolidityFunctionParameter(name: "tokenId", type: .uint256)]
      
      let outputs = [
        SolidityFunctionParameter(name: "hasBid", type: .bool),
        SolidityFunctionParameter(name: "phunkIndex", type: .uint256),
        SolidityFunctionParameter(name: "bidder", type: .address),
        SolidityFunctionParameter(name: "value", type: .uint256)
      ]
      
      let method = SolidityConstantFunction(name: "phunkBids", inputs: inputs, outputs: outputs, handler: self)
      print("calling phunkBids")
      return method.invoke(tokenId).call()
        .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs in
          return outputs["hasBid"] as! Bool ? (outputs["value"] as? BigUInt).flatMap(priceIfNotZero) : nil
        }
    }
    
    func enterBidForPhunk(tokenId: BigUInt,wei:BigUInt,from:EthereumAddress) -> EthereumTransaction {
      // function enterBidForPunk(uint punkIndex) payable {
      
      let inputs = [SolidityFunctionParameter(name: "phunkIndex", type: .uint256)]
      let method = SolidityPayableFunction(name: "enterBidForPhunk", inputs: inputs, outputs: [], handler: self)
      
      return method.invoke(tokenId).createTransaction(
        nonce: nil,
        from: from,
        value:EthereumQuantity(quantity: wei),
        gas: 200000,
        gasPrice: nil)!
    }
    
    func buyPhunk(tokenId: BigUInt,wei:BigUInt,from:EthereumAddress) -> EthereumTransaction {
      //  function buyPunk(uint punkIndex) payable {
      
      let inputs = [SolidityFunctionParameter(name: "phunkIndex", type: .uint256)]
      let method = SolidityPayableFunction(name: "buyPhunk", inputs: inputs, outputs: [], handler: self)
      
      return method.invoke(tokenId).createTransaction(
        nonce: nil,
        from: from,
        value:EthereumQuantity(quantity: wei),
        gas: 200000,
        gasPrice: nil)!
    }
  }
  
  private var ethContract = EthContract()
  
  struct TradeActions : TradeActionsInterface {
    let ethContract : EthContract
    func submitBid(tokenId: UInt, wei: BigUInt, wallet: WalletProvider) -> Promise<EthereumTransactionReceiptObject> {
      print("submitting enterBidForPunk")
      return wallet.sendTransaction(tx:
                                      ethContract.enterBidForPhunk(tokenId:BigUInt(tokenId),wei: wei,from: wallet.account))
    }
    
    func acceptOffer(tokenId: UInt, wei: BigUInt, wallet: WalletProvider) -> Promise<EthereumTransactionReceiptObject> {
      print("submitting buyPunk")
      return wallet.sendTransaction(tx:
                                      ethContract.buyPhunk(tokenId:BigUInt(tokenId),wei: wei,from: wallet.account))
    }
  }
  
  struct TradeInterface : TokenTradeInterface {
    
    var actions: TradeActionsInterface? {
      return TradeActions(ethContract: ethContract)
    }
    
    let ethContract : EthContract
    
    func getBidAsk(_ tokenId: UInt) -> Promise<BidAsk> {
      
      ethContract.phunkBids(BigUInt(tokenId))
        .then { bidPrice in
          ethContract.phunksOfferedForSale(BigUInt(tokenId))
            .map { askPrice in
              return BidAsk(
                bid:bidPrice.map { BidInfo(wei:$0,expiration_time:nil) },
                ask:askPrice.map { AskInfo(wei:$0,expiration_time:nil) }
              )
            }
        }
    }
    
    func getBidAsk(_ tokenIds: [UInt]) -> Promise<[(tokenId:UInt,bidAsk:BidAsk)]> {
      return getBidAskSerial(tokenIds: tokenIds, getter: self.getBidAsk)
    }
  }
  
  var tradeActions: TokenTradeInterface?
  var collectionContract : UrlCollectionContract
  
  init () {
    collectionContract = UrlCollectionContract(
      name: "Phunks",
      address: "0xf07468eAd8cf26c752C676E43C814FEe9c8CF402",
      tokenUri: { "ipfs://QmSv6qnW1zCqiYBHCJKbfBu8YAcJefUYtPsDea3TsG2PHz/notpunk\(String(format: "%04d", $0)).png"})
    tradeActions = TradeInterface(ethContract:ethContract)
  }
  
  var name = "Phunks"
  var contractAddressHex = "0xf07468eAd8cf26c752C676E43C814FEe9c8CF402"
  
  func getRecentTrades(onDone: @escaping () -> Void, _ response: @escaping (NFTWithPrice) -> Void) {
    return collectionContract.getRecentTrades(onDone: onDone, response)
  }
  
  func refreshLatestTrades(onDone: @escaping () -> Void, _ response: @escaping (NFTWithPrice) -> Void) {
    return collectionContract.refreshLatestTrades(onDone: onDone, response)
  }
  
  func getNFT(_ tokenId: UInt) -> NFT {
    return collectionContract.getNFT(tokenId)
  }
  
  func getToken(_ tokenId: UInt) -> NFTWithLazyPrice {
    return collectionContract.getToken(tokenId)
  }
  
  func ownerOf(_ tokenId: UInt) -> Promise<EthereumAddress?> {
    return collectionContract.ownerOf(tokenId)
  }
  
  func getOwnerTokens(address: EthereumAddress, onDone: @escaping () -> Void, _ response: @escaping (NFTWithLazyPrice) -> Void) {
    return collectionContract.getOwnerTokens(address: address, onDone: onDone, response)
  }
  
  func getEventsFetcher(_ tokenId: UInt) -> TokenEventsFetcher? {
    return collectionContract.getEventsFetcher(tokenId)
  }
  
  
}
