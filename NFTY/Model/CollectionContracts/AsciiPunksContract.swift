//
//  AsciiPunksContract.swift
//  NFTY
//
//  Created by Varun Kohli on 8/21/21.
//

import Cache
import Web3
import Web3ContractABI
import PromiseKit
import Foundation

class AsciiPunksContract : ContractInterface {
  
  private var drawingCache = try! DiskStorage<BigUInt, Media.AsciiPunk>(
    config: DiskConfig(name: "AsciiPunksDrawingsCache",expiry: .never),
    transformer: TransformerFactory.forCodable(ofType: Media.AsciiPunk.self))
  
  private var pricesCache : [UInt : ObservablePromise<NFTPriceStatus>] = [:]
  
  private let Transfer: SolidityEvent = SolidityEvent(name: "Transfer", anonymous: false, inputs: [
    SolidityEvent.Parameter(name: "from", type: .address, indexed: true),
    SolidityEvent.Parameter(name: "to", type: .address, indexed: true),
    SolidityEvent.Parameter(name: "tokenId", type: .uint256, indexed: true),
  ])
  
  private var name = "AsciiPunks"
  
  let contractAddressHex = "0x5283Fc3a1Aac4DaC6B9581d3Ab65f4EE2f3dE7DC"
  var tradeActions: TokenTradeInterface? = OpenSeaTradeApi(contract: try! EthereumAddress(hex: "0x5283Fc3a1Aac4DaC6B9581d3Ab65f4EE2f3dE7DC", eip55: false))
  private var transfer : LogsFetcher
  private let initFromBlock : BigUInt
  
  class EthContract : EthereumContract {
    let eth = web3.eth
    let events : [SolidityEvent] = []
    let addressHex = "0x5283Fc3a1Aac4DaC6B9581d3Ab65f4EE2f3dE7DC"
    var address : EthereumAddress?
    init() {
      address = try? EthereumAddress(hex:addressHex, eip55: false)
    }
    
    func draw(_ tokenId:BigUInt) -> Promise<Media.AsciiPunk?> {
      let inputs = [SolidityFunctionParameter(name: "tokenId", type: .uint256)]
      let outputs = [SolidityFunctionParameter(name: "uri", type: .string)]
      let method = SolidityConstantFunction(name: "draw", inputs: inputs, outputs: outputs, handler: self)
      print("calling draw")
      return
        method.invoke(tokenId).call()
        .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs in
          return Media.AsciiPunk(unicode:outputs["uri"] as! String)
        }
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
        .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs in
          return outputs["tokenId"] as! BigUInt
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
  private var ethContract = EthContract()
  private var erc721Contract = Erc721Contract(address:"0x5283Fc3a1Aac4DaC6B9581d3Ab65f4EE2f3dE7DC")
  
  func getEventsFetcher(_ tokenId: UInt) -> TokenEventsFetcher? {
    return erc721Contract.getEventsFetcher(tokenId)
  }
  
  init () {
    initFromBlock = (UserDefaults.standard.string(forKey: "\(contractAddressHex).initFromBlock").flatMap { BigUInt($0)}) ?? INIT_BLOCK
    transfer = LogsFetcher(event:Transfer,fromBlock:initFromBlock,address:contractAddressHex,indexedTopics: [],blockDecrements: nil)
  }
  
  private func draw(_ tokenId:BigUInt) -> ObservablePromise<Media.AsciiPunk?> {
    switch(try? drawingCache.object(forKey:tokenId)) {
    case .some(let p):
      return ObservablePromise(resolved: p)
    case .none:
      let p = ethContract.draw(tokenId);
      let observable = ObservablePromise(promise: p) { drawing in
        drawing.flatMap {
          try? self.drawingCache.setObject($0, forKey: tokenId)
        }
      }
      return observable
    }
  }
  
  private func eventOfTx(transactionHash:EthereumData?,eventType:TradeEventType) -> Promise<TradeEvent?> {
    
    txFetcher.eventOfTx(transactionHash: transactionHash)
      .map(on:DispatchQueue.global(qos:.userInteractive)) { (txData:TxFetcher.TxInfo?) in
        switch(txData) {
        case .none: return nil
        case .some(let tx):
          return TradeEvent(type:eventType,value:.wei(tx.value),blockNumber:.ethereum(tx.blockNumber))
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
                return TradeEvent(type:eventType,value:.wei(tx.value),blockNumber:.ethereum(tx.blockNumber))
              }
            }
        case .some:
          return Promise.value(event)
        }
      }
  }
  
  func getRecentTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
    return transfer.fetch(onDone:onDone,retries:10) { log in
      let res = try! web3.eth.abi.decodeLog(event:self.Transfer,from:log);
      let tokenId = UInt(res["tokenId"] as! BigUInt);
      let isMint = res["from"] as! EthereumAddress == EthereumAddress(hexString: "0x0000000000000000000000000000000000000000")!
      
      response(NFTWithPrice(
        nft:NFT(
          address:self.contractAddressHex,
          tokenId:tokenId,
          name:self.name,
          media:.asciiPunk(Media.AsciiPunkLazy(tokenId:BigUInt(tokenId), draw: self.draw))),
        blockNumber:log.blockNumber.map { .ethereum($0) },
        indicativePrice:.lazy {
          ObservablePromise(
            promise:
              self.eventOfTx(transactionHash:log.transactionHash,eventType:isMint ? .minted : .bought)
              .map {
                let price = priceIfNotZero($0?.value);
                return NFTPriceStatus.known(
                  NFTPriceInfo(
                    wei:price,
                    blockNumber:log.blockNumber.map { .ethereum($0) },
                    type: isMint ? .minted : price.map { _ in TradeEventType.bought } ?? TradeEventType.transfer))
              }
          )
        }
      ))
    }
  }
  
  func refreshLatestTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
    return transfer.updateLatest(onDone:onDone) { index,log in
      let res = try! web3.eth.abi.decodeLog(event:self.Transfer,from:log);
      let tokenId = UInt(res["tokenId"] as! BigUInt);
      let isMint = res["from"] as! EthereumAddress == EthereumAddress(hexString: "0x0000000000000000000000000000000000000000")!
      response(NFTWithPrice(
        nft:NFT(
          address:self.contractAddressHex,
          tokenId:tokenId,
          name:self.name,
          media:.asciiPunk(Media.AsciiPunkLazy(tokenId:BigUInt(tokenId), draw: self.draw))),
        blockNumber:log.blockNumber.map { .ethereum($0) },
        indicativePrice:.lazy {
          ObservablePromise(
            promise:
              self.eventOfTx(transactionHash:log.transactionHash,eventType:isMint ? .minted : .bought)
              .map {
                let price = priceIfNotZero($0?.value);
                return NFTPriceStatus.known(
                  NFTPriceInfo(
                    wei:price,
                    blockNumber:log.blockNumber.map { .ethereum($0) },
                    type: isMint ? .minted : price.map { _ in TradeEventType.bought } ?? TradeEventType.transfer))
              }
          )
        }
      ))
    }
  }
  
  private func getTokenHistory(_ tokenId: UInt) -> Promise<TradeEventStatus> {
    
    let tokenIdTopic = try! ABI.encodeParameter(SolidityWrappedValue.uint(BigUInt(tokenId)))
    let transerFetcher = LogsFetcher(
      event:self.Transfer,
      fromBlock:self.initFromBlock,
      address:self.contractAddressHex,
      indexedTopics: [nil,nil,tokenIdTopic],
      blockDecrements: 100000)
    
    
    var events : [Promise<TradeEvent?>] = []
    return Promise { seal in
      transerFetcher.fetchAllLogs(onDone:{
        when(fulfilled:events)
          .done(on:DispatchQueue.global(qos:.userInteractive)) { events in
            seal.fulfill(events.filter { $0 != nil }.map { $0! })
          }.catch {
            print ($0)
            seal.fulfill([])
          }
      }) { log in
        let res = try! web3.eth.abi.decodeLog(event:self.Transfer,from:log);
        let isMint = res["from"] as! EthereumAddress == EthereumAddress(hexString: "0x0000000000000000000000000000000000000000")!
        events.append(self.eventOfTx(transactionHash:log.transactionHash,eventType:isMint ? .minted : .bought))
      }
    }
    .compactMap(on:DispatchQueue.global(qos:.userInteractive)) { events in
      events.sorted(by: { $0.blockNumber > $1.blockNumber})
    }.then(on:DispatchQueue.global(qos:.userInteractive)) { events -> Promise<TradeEventStatus> in
      switch(events.count) {
      case 0:
        return Promise.value(
          TradeEventStatus.notSeenSince(
            NFTNotSeenSince(
              blockNumber:.ethereum(EthereumQuantity(quantity: transerFetcher.fromBlock))
            )
          )
        )
      default:
        return Promise.value(TradeEventStatus.trade(events.first!))
      }
    }
  }
  
  func getNFT(_ tokenId: UInt) -> NFT {
    NFT(
      address:self.contractAddressHex,
      tokenId:tokenId,
      name:self.name,
      media:.asciiPunk(Media.AsciiPunkLazy(tokenId:BigUInt(tokenId), draw: self.draw)))
  }
  
  
  func getToken(_ tokenId: UInt) -> NFTWithLazyPrice {
    NFTWithLazyPrice(
      nft:getNFT(tokenId),
      getPrice: {
        switch(self.pricesCache[tokenId]) {
        case .some(let p):
          return p
        case .none:
          let p =
            self.getTokenHistory(tokenId)
            .map(on:DispatchQueue.global(qos:.userInteractive)) { (event:TradeEventStatus) -> NFTPriceStatus in
              switch(event) {
              case .trade(let event):
                return NFTPriceStatus.known(NFTPriceInfo(wei:priceIfNotZero(event.value),blockNumber:event.blockNumber,type:event.type))
              case .notSeenSince(let since):
                return NFTPriceStatus.notSeenSince(since)
              }
            }
          let observable = ObservablePromise(promise: p)
          DispatchQueue.main.async {
            self.pricesCache[tokenId] = observable
          }
          return observable
        }
      }
    )
  }
  
  func getOwnerTokens(address: EthereumAddress, onDone: @escaping () -> Void, _ response: @escaping (NFTWithLazyPrice) -> Void) {
    ethContract.balanceOf(address:address)
      .then(on:DispatchQueue.global(qos: .userInteractive)) { tokensNum -> Promise<Void> in
        if (tokensNum <= 0) {
          return Promise.value(())
        } else {
          return when(
            fulfilled:
              Array(0...tokensNum-1).map { index -> Promise<Void> in
                return
                  self.ethContract.tokenOfOwnerByIndex(address: address,index:index)
                  .map { tokenId in
                    return self.getToken(UInt(tokenId))
                  }.done {
                    response($0)
                  }
              }
          )
        }
      }.done(on:DispatchQueue.global(qos:.userInteractive)) { (promises:Void) -> Void in
        onDone()
      }.catch {
        print ($0)
        onDone()
      }
  }
  
  func ownerOf(_ tokenId: UInt) -> Promise<EthereumAddress?> {
    return ethContract.ownerOf(BigUInt(tokenId)).map { addressIfNotZero($0) }
  }
  
  func indicativeFloor() -> Promise<PriceUnit?> {
    return OpenSeaApi.getCollectionStats(contract:self.contractAddressHex)
      .map { stats in stats?.floor_price }
  }
  
  var vaultContract : CollectionVaultContract? = nil
 
  func floorFetcher(_ collection:Collection) -> PagedTokensFetcher? {
    return OpenSeaFloorFetcher.make(collection:collection)
  }
  
}

