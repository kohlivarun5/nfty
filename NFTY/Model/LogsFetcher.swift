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
import PromiseKit

public enum EthereumGetLogTopics : Decodable {
  case or([String?])
  case and(String?)
}

extension EthereumGetLogTopics : Encodable {
  public func encode(to encoder: Encoder) throws {
    switch(self) {
    case .or(let topics):
      var container = encoder.unkeyedContainer()
      topics.forEach { try! container.encode($0) }
    case .and(let topic):
      var container = encoder.singleValueContainer()
      try! container.encode(topic)
    }
  }
}

public struct EthereumGetLogParams: Codable {
  public var fromBlock: EthereumQuantityTag?
  public var toBlock: EthereumQuantityTag?
  public var address: EthereumAddress?
  public var topics:[EthereumGetLogTopics]
}

extension Web3.Eth {
  public typealias Web3ResponseCompletion<Result: Codable> = (_ resp: Web3Response<Result>) -> Void
  public func getLogs(
    params: EthereumGetLogParams,
    response: @escaping Web3ResponseCompletion<[EthereumLogObject]>
  ) {
    print("calling web3.eth.getLogs")// with fromBlock=\(String(describing:params.fromBlock)) -> toBlock=\(String(describing:params.toBlock))")
    let req = RPCRequest<[EthereumGetLogParams]>(
      id: properties.rpcId,
      jsonrpc: Web3.jsonrpc,
      method: "eth_getLogs",
      params: [params]
    )
    properties.provider.send(request: req, response: response)
  }
}

class LogsFetcher {
  private let blockDecrements : BigUInt
  private let searchBlocks : BigUInt
  private var toBlock = EthereumQuantityTag.latest
  private var mostRecentBlock = EthereumQuantityTag.latest
  
  let event : SolidityEvent
  var fromBlock : BigUInt
  var address : String?
  
  var topics : [EthereumGetLogTopics]
  
  let cacheId : String
  
  init(event:SolidityEvent,fromBlock:BigUInt,address:String,indexedTopics:[String?],blockDecrements:BigUInt?) {
    self.event = event;
    self.fromBlock = fromBlock;
    self.address = address
    var topics = [
      EthereumGetLogTopics.and(web3.eth.abi.encodeEventSignature(self.event))
    ]
    indexedTopics.forEach {
      topics.append(EthereumGetLogTopics.and($0))
    }
    self.topics = topics
    self.searchBlocks = 500
    self.blockDecrements = blockDecrements ?? 500 * 4
    self.cacheId = "\(address).initFromBlock"
  }
  
  init(event:SolidityEvent,fromBlock:BigUInt,address:String?,cacheId:String,topics:[EthereumGetLogTopics],blockDecrements:BigUInt?) {
    self.event = event;
    self.fromBlock = fromBlock;
    self.address = address
    self.topics = [
      .and(web3.eth.abi.encodeEventSignature(self.event))
    ]
    self.topics.append(contentsOf: topics)
    self.searchBlocks = 500
    self.blockDecrements = blockDecrements ?? 500 * 4
    
    self.cacheId = cacheId
    
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
        switch (UserDefaults.standard.string(forKey: cacheId).flatMap { BigUInt($0)}) {
        case .some(let prev):
          UserDefaults.standard.set(String(max(prev,seen - searchBlocks)),forKey: cacheId)
        case .none:
          UserDefaults.standard.set(String(seen - searchBlocks),forKey: cacheId)
        }
      default:
        break
      }
      
    case .none:
      break
    }
  }
  
  func updateLatest(onDone: @escaping () -> Void,_ response: @escaping (Int,EthereumLogObject) -> Void) {
    if (self.mostRecentBlock == .latest) {
      return onDone()
    }
    
    return web3.eth.getLogs(
      params:EthereumGetLogParams(
        fromBlock:self.mostRecentBlock,
        toBlock: EthereumQuantityTag.latest,
        address:self.address.map { try! EthereumAddress(hex: $0, eip55: false) },
        topics: self.topics
      )
    ) { result in
      DispatchQueue.global(qos:.userInteractive).async {
        if case let logs? = result.result {
          logs.indices.forEach { index in
            let log = logs[index];
            response(index,log)
            self.updateMostRecent(log.blockNumber)
          }
        } else {
          print(result)
        }
        onDone()
      }
    }
  }
  
  func fetch(onDone: @escaping () -> Void,retries:Int = 0,_ response: @escaping (EthereumLogObject) -> Void) {
    print("Logs.fetch")
    let params = EthereumGetLogParams(
      fromBlock:.block(self.fromBlock),
      toBlock: self.toBlock,
      address:self.address.map { try! EthereumAddress(hex: $0, eip55: false) },
      topics: self.topics
    )
    
    // print("Logs=\(params)")
    return web3.eth.getLogs(params:params) { result in
      DispatchQueue.global(qos:.userInteractive).async {
        if case let logs? = result.result {
          self.toBlock = EthereumQuantityTag.block(self.fromBlock)
          self.fromBlock = self.fromBlock - self.blockDecrements
          
          // print("Found \(logs.count) logs")
          logs.sorted {
            switch($0.blockNumber?.quantity,$1.blockNumber?.quantity) {
            case (.some(let x),.some(let y)):
              return x > y
            case (.some,.none):
              return true
            case (.none,.some):
              return false
            case (.none,.none):
              return false
            }
          }.forEach { log in
            response(log)
            self.updateMostRecent(log.blockNumber)
          }
          
          if (logs.isEmpty && retries > 0) {
            return self.fetch(onDone:onDone,retries:retries-1,response);
          }
          
        } else {
          print(result)
        }
        onDone()
      }
    }
  }
  
  func fetchWithPromise(onDone: @escaping (Bool) -> Promise<Int>,limit:Int,retries:Int = 0,_ response: @escaping (EthereumLogObject) -> Void) {
    
    print("fetchWithPromise",self.fromBlock,self.toBlock)
    let params = EthereumGetLogParams(
      fromBlock:.block(self.fromBlock),
      toBlock: self.toBlock,
      address:self.address.map { try! EthereumAddress(hex: $0, eip55: false) },
      topics: self.topics
    )
    
    // print("Logs=\(params)")
    
    return web3.eth.getLogs(params:params) { result in
      DispatchQueue.global(qos:.userInteractive).async {
        // print("fetchWithPromise",result.result?.count)
        if case let logs? = result.result {
          self.toBlock = EthereumQuantityTag.block(self.fromBlock - 1)
          self.fromBlock = self.fromBlock - 1 - self.blockDecrements
          // print("fetchWithPromise after",self.fromBlock,self.toBlock)
          
          // print("Found \(logs.count) logs")
          logs.sorted {
            switch($0.blockNumber?.quantity,$1.blockNumber?.quantity) {
            case (.some(let x),.some(let y)):
              return x > y
            case (.some,.none):
              return true
            case (.none,.some):
              return false
            case (.none,.none):
              return false
            }
          }.forEach { log in
            self.updateMostRecent(log.blockNumber)
            response(log)
          }
          
          _ = onDone(retries <= 0)
            .map { processed in
              // print("Done with ",processed,limit,retries)
              if (processed < limit && retries > 0) {
                self.fetchWithPromise(onDone:onDone,limit:limit,retries:retries-1,response);
              }
            }
        } else {
          print(result)
          _ = onDone(retries <= 0)
        }
        
      }
    }
  }
  
  func fetchAllLogs(onDone: @escaping () -> Void,retries:Int = 0,_ response: @escaping (EthereumLogObject) -> Void) {
    
    web3.eth.getLogs(
      params:EthereumGetLogParams(
        fromBlock:.block(0),
        toBlock: .latest,
        address:self.address.map { try! EthereumAddress(hex: $0, eip55: false) },
        topics: self.topics
      )
    ) { result in
      DispatchQueue.global(qos:.userInteractive).async {
        if case let logs? = result.result {
          logs.sorted {
            switch($0.blockNumber?.quantity,$1.blockNumber?.quantity) {
            case (.some(let x),.some(let y)):
              return x > y
            case (.some,.none):
              return true
            case (.none,.some):
              return false
            case (.none,.none):
              return false
            }
          }.forEach { log in
            response(log)
          }
        } else {
          print(result)
        }
        onDone()
      }
    }
  }
  
  
}
