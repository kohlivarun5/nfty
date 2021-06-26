//
//  LogsFetcher.swift
//  NFTY
//
//  Created by Varun Kohli on 6/26/21.
//

import Foundation
import BigInt
import Web3
import Web3ContractABI

class LogsFetcher {
  private let blockDecrements : BigUInt
  private let searchBlocks : BigUInt
  private var toBlock = EthereumQuantityTag.latest
  private var mostRecentBlock = EthereumQuantityTag.latest
  
  let event : SolidityEvent
  var fromBlock : BigUInt
  var address : String
  var topics : [String?]
  
  init(event:SolidityEvent,fromBlock:BigUInt,address:String,indexedTopics:[String?],blockDecrements:BigUInt?) {
    self.event = event;
    self.fromBlock = fromBlock;
    self.address = address
    self.topics = [
      web3.eth.abi.encodeEventSignature(self.event)
    ]
    self.topics.append(contentsOf: indexedTopics)
    self.searchBlocks = 500
    self.blockDecrements = blockDecrements ?? 500 * 4
  }
  
  private func updateMostRecent(_ blockNumber:EthereumQuantity?) {
    
    switch (blockNumber) {
    case .some(let blockNum):
      switch (self.mostRecentBlock.tagType) {
      case .block(let seen):
        self.mostRecentBlock = .block(max(seen,blockNum.quantity + 1)) // +1 as fromBlock is inclusive otherwise
      default:
        self.mostRecentBlock = .block(blockNum.quantity + 1)
      }
      
      switch (self.mostRecentBlock.tagType) {
      case .block(let seen):
        switch (UserDefaults.standard.string(forKey: "\(address).initFromBlock").flatMap { BigUInt($0)}) {
        case .some(let prev):
          UserDefaults.standard.set(String(max(prev,seen - searchBlocks)),forKey: "\(address).initFromBlock")
        case .none:
          UserDefaults.standard.set(String(seen - searchBlocks),forKey: "\(address).initFromBlock")
        }
      default:
        break
      }
      
    case .none:
      break
    }
  }
  
  func updateLatest(onDone: @escaping () -> Void,_ response: @escaping (EthereumLogObject) -> Void) {
    if (self.mostRecentBlock == .latest) {
      return onDone()
    }
    
    return web3.eth.getLogs(
      params:EthereumGetLogParams(
        fromBlock:self.mostRecentBlock,
        toBlock: EthereumQuantityTag.latest,
        address:try! EthereumAddress(hex: self.address, eip55: false),
        topics: self.topics
      )
    ) { result in
      if case let logs? = result.result {
        logs.indices.forEach { index in
          let log = logs[index];
          response(log)
          self.updateMostRecent(log.blockNumber)
        }
      } else {
        print(result)
      }
      onDone()
    }
  }
  
  func fetch(onDone: @escaping () -> Void,retries:Int = 0,_ response: @escaping (EthereumLogObject) -> Void) {
    
    return web3.eth.getLogs(
      params:EthereumGetLogParams(
        fromBlock:.block(self.fromBlock),
        toBlock: self.toBlock,
        address:try! EthereumAddress(hex: self.address, eip55: false),
        topics: self.topics
      )
    ) { result in
      if case let logs? = result.result {
        self.toBlock = EthereumQuantityTag.block(self.fromBlock)
        self.fromBlock = self.fromBlock - self.blockDecrements
        
        logs.indices.forEach { index in
          let log = logs[index];
          response(log)
          self.updateMostRecent(log.blockNumber)
        }
        
        if (logs.count == 0 && retries > 0) {
          return self.fetch(onDone:onDone,retries:retries-1,response);
        }
        
      } else {
        print(result)
      }
      onDone()
    }
  }
}
