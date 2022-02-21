//
//  Erc721Contract.swift
//  NFTY
//
//  Created by Varun Kohli on 5/11/21.
//

import Foundation
import Web3
import Web3PromiseKit
import Web3ContractABI
import Cache

class Erc721Contract {
  
  // private var imagesCache : [BigUInt : ObservablePromise<URL>] = [:]
  var pricesCache : [UInt : ObservablePromise<NFTPriceStatus>] = [:]
  
  let Transfer: SolidityEvent = SolidityEvent(name: "Transfer", anonymous: false, inputs: [
    SolidityEvent.Parameter(name: "from", type: .address, indexed: true),
    SolidityEvent.Parameter(name: "to", type: .address, indexed: true),
    SolidityEvent.Parameter(name: "tokenId", type: .uint256, indexed: true),
  ])
  
  
  let contractAddressHex : String
  var transfer : LogsFetcher
  let initFromBlock : BigUInt
  
  class EthContract : EthereumContract {
    let eth = web3.eth
    let events : [SolidityEvent] = []
    var address : EthereumAddress?
    init(_ addressHex:String) {
      address = try? EthereumAddress(hex:addressHex, eip55: false)
    }
    
    func balanceOf(address:EthereumAddress) -> Promise<BigUInt> {
      let inputs = [SolidityFunctionParameter(name: "owner", type: .address)]
      let outputs = [SolidityFunctionParameter(name: "tokens", type: .uint256)]
      let method = SolidityConstantFunction(name: "balanceOf", inputs: inputs, outputs: outputs, handler: self)
      print("calling balanceOf")
      return
        method.invoke(address).call()
        .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs in
          return outputs["tokens"] as! BigUInt
        }
    }
    
    func tokenOfOwnerByIndex(address:EthereumAddress,index:BigUInt) -> Promise<BigUInt> {
      let inputs = [
        SolidityFunctionParameter(name: "owner", type: .address),
        SolidityFunctionParameter(name: "index", type: .uint256)]
      let outputs = [SolidityFunctionParameter(name: "tokenId", type: .uint256)]
      let method = SolidityConstantFunction(name: "tokenOfOwnerByIndex", inputs: inputs, outputs: outputs, handler: self)
      print("calling tokenOfOwnerByIndex")
      return
        method.invoke(address,index).call()
        .map(on:DispatchQueue.global(qos:.userInitiated)) { outputs in
          return outputs["tokenId"] as! BigUInt
        }
    }
    
    
    func tokenURI(tokenId: BigUInt) -> Promise<String> {
      let inputs = [SolidityFunctionParameter(name: "tokenId", type: .uint256)]
      let outputs = [SolidityFunctionParameter(name: "tokenURI", type: .string)]
      let method = SolidityConstantFunction(name: "tokenURI", inputs: inputs, outputs: outputs, handler: self)
      print("calling tokenURI @ \(address?.hex(eip55:true) ?? "?")")
      return method.invoke(tokenId).call()
        .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs in
          return outputs["tokenURI"] as! String
        }
    }
    
    
    func ownerOf(_ tokenId:BigUInt) -> Promise<EthereumAddress> {
      let inputs = [SolidityFunctionParameter(name: "tokenId", type: .uint256)]
      let outputs = [SolidityFunctionParameter(name: "address", type: .address)]
      let method = SolidityConstantFunction(name: "ownerOf", inputs: inputs, outputs: outputs, handler: self)
      print("calling ownerOf")
      return
        method.invoke(tokenId).call()
        .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs in
          return outputs["address"] as! EthereumAddress
        }
    }
  }
  
  var ethContract : EthContract
  
  init (address:String) {
    self.contractAddressHex = address
    ethContract = EthContract(address)
    initFromBlock = (UserDefaults.standard.string(forKey: "\(address).initFromBlock").flatMap { BigUInt($0)}) ?? INIT_BLOCK
    transfer = LogsFetcher(event:Transfer,fromBlock:initFromBlock,address:contractAddressHex,indexedTopics: [],blockDecrements: nil)
  }
  
  func eventOfTx(transactionHash:EthereumData?,eventType:TradeEventType) -> Promise<TradeEvent?> {
    return txFetcher.eventOfTx(transactionHash: transactionHash)
      .map(on:DispatchQueue.global(qos:.userInitiated)) { (txData:TxFetcher.TxInfo?) in
        switch(txData) {
        case .none: return nil
        case .some(let tx):
          return TradeEvent(type:eventType,value:.wei(tx.value),blockNumber:tx.blockNumber)
        }
      }
      .then (on:DispatchQueue.global(qos:.userInitiated)) { (event:TradeEvent?) -> Promise<TradeEvent?> in
        switch(event?.value) {
        case .none,.some(.wei(0)):
          return wethFetcher.valueOfTx(transactionHash: transactionHash)
            .map(on:DispatchQueue.global(qos:.userInitiated)) { (txData:WETHFetcher.Info?) in
              switch(txData) {
              case .none: return nil
              case .some(let tx):
                return TradeEvent(type:eventType,value:.wei(tx.value),blockNumber:tx.blockNumber)
              }
            }
        case .some:
          return Promise.value(event)
        }
      }
  }
  
  func getTokenHistory(_ tokenId: UInt) -> Promise<TradeEventStatus> {
    
    let tokenIdTopic = try! ABI.encodeParameter(SolidityWrappedValue.uint(BigUInt(tokenId)))
    let fetcher = LogsFetcher(
      event:self.Transfer,
      fromBlock:self.initFromBlock,
      address:self.contractAddressHex,
      indexedTopics: [nil,nil,tokenIdTopic],
      blockDecrements: 10000)
    
    
    var events : [Promise<TradeEvent?>] = []
    return Promise { seal in
      fetcher.fetchAllLogs(onDone:{
        when(fulfilled:events)
          .done(on:DispatchQueue.global(qos:.userInteractive)) { events in
            seal.fulfill(events.filter { $0 != nil }.map { $0! })
          }.catch { print ($0) }
      }) { log in
        let res = try! web3.eth.abi.decodeLog(event:self.Transfer,from:log)
        let isMint = res["from"] as! EthereumAddress == EthereumAddress(hexString: "0x0000000000000000000000000000000000000000")!
        events.append(self.eventOfTx(transactionHash:log.transactionHash,eventType:isMint ? .minted : .bought))
      }
    }
    .compactMap(on:DispatchQueue.global(qos:.userInteractive)) { events in
      events.sorted(by: { $0.blockNumber.quantity > $1.blockNumber.quantity})
    }.then(on:DispatchQueue.global(qos:.userInteractive)) { events -> Promise<TradeEventStatus> in
      switch(events.count) {
      case 0:
        return Promise.value(
          TradeEventStatus.notSeenSince(
            NFTNotSeenSince(
              blockNumber:fetcher.fromBlock
            )
          )
        )
      default:
        return Promise.value(TradeEventStatus.trade(events.first!))
      }
    }
  }
  
  func ownerOf(_ tokenId: UInt) -> Promise<EthereumAddress?> {
    return ethContract.ownerOf(BigUInt(tokenId)).map { addressIfNotZero($0) }
  }
  
  class EventsFetcher : TokenEventsFetcher {
    let Transfer: SolidityEvent = SolidityEvent(name: "Transfer", anonymous: false, inputs: [
      SolidityEvent.Parameter(name: "from", type: .address, indexed: true),
      SolidityEvent.Parameter(name: "to", type: .address, indexed: true),
      SolidityEvent.Parameter(name: "tokenId", type: .uint256, indexed: true),
    ])
    
    let transferFetcher : LogsFetcher
    init(tokenId:BigUInt,contractAddressHex:String,initFromBlock:BigUInt) {
      let tokenIdTopic = try! ABI.encodeParameter(SolidityWrappedValue.uint(BigUInt(tokenId)))
      self.transferFetcher = LogsFetcher(
        event:self.Transfer,
        fromBlock:initFromBlock,
        address:contractAddressHex,
        indexedTopics: [nil,nil,tokenIdTopic],
        blockDecrements: 10000)
    }
    
    func getEvents(onDone: @escaping () -> Void,_ response: @escaping (TradeEvent) -> Void) {
      var reachedMint = false
      
      return transferFetcher.fetchAllLogs(onDone: {
        if (reachedMint) { onDone() }
      }) { log in
        let res = try! web3.eth.abi.decodeLog(event:self.Transfer,from:log)
        let from = res["from"] as! EthereumAddress
        
        var type : TradeEventType? = nil
        
        if (from == EthereumAddress(hexString: "0x0000000000000000000000000000000000000000")) {
          reachedMint = true
          type = .minted
        }
          
        txFetcher.eventOfTx(transactionHash: log.transactionHash)
          .map(on:DispatchQueue.global(qos:.userInitiated)) { (txData:TxFetcher.TxInfo?) in
            switch(txData) {
            case .none:
              return TradeEvent(type:type ?? .transfer,value:.wei(BigUInt(0)),blockNumber:log.blockNumber!)
            case .some(let tx):
              return TradeEvent(type:type ?? .bought,value:.wei(tx.value),blockNumber:tx.blockNumber)
            }
          }
          .then (on:DispatchQueue.global(qos:.userInitiated)) { (event:TradeEvent) -> Promise<TradeEvent> in
            switch(event.value) {
            case .wei(0):
              return wethFetcher.valueOfTx(transactionHash: log.transactionHash)
                .map(on:DispatchQueue.global(qos:.userInitiated)) { (txData:WETHFetcher.Info?) in
                  switch(txData) {
                  case .none:
                    return event
                  case .some(let tx):
                    return TradeEvent(type:type ?? .bought,value:.wei(tx.value),blockNumber:tx.blockNumber)
                  }
                }
            default:
              return Promise.value(event)
            }
          }
          .done { response($0) }
          .catch { print($0) }
      }
    }
  }
  
  func getEventsFetcher(_ tokenId: UInt) -> TokenEventsFetcher? {
    return EventsFetcher(tokenId:BigUInt(tokenId),contractAddressHex:self.contractAddressHex,initFromBlock:self.initFromBlock)
  }
}
