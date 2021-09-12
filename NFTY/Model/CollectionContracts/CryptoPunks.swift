//
//  CryptoPunks.swift
//  NFTY
//
//  Created by Varun Kohli on 7/27/21.
//

import Foundation
import Web3
import Web3PromiseKit
import Web3ContractABI

class CryptoPunksContract : ContractInterface {
  
  private var pricesCache : [UInt : ObservablePromise<NFTPriceStatus>] = [:]
  
  private let PunkBought: SolidityEvent = SolidityEvent(name: "PunkBought", anonymous: false, inputs: [
    SolidityEvent.Parameter(name: "punkIndex", type: .uint256, indexed: true),
    SolidityEvent.Parameter(name: "value", type: .uint256, indexed: false),
    SolidityEvent.Parameter(name: "fromAddress", type: .address, indexed: true),
    SolidityEvent.Parameter(name: "toAddress", type: .address, indexed: true)
  ])
  
  private let PunkOffered: SolidityEvent = SolidityEvent(name: "PunkOffered", anonymous: false, inputs: [
    SolidityEvent.Parameter(name: "punkIndex", type: .uint256, indexed: true),
    SolidityEvent.Parameter(name: "minValue", type: .uint256, indexed: false),
    SolidityEvent.Parameter(name: "toAddress", type: .address, indexed: true)
  ])
  
  private let PunkBidEntered: SolidityEvent = SolidityEvent(name: "PunkBidEntered", anonymous: false, inputs: [
    SolidityEvent.Parameter(name: "punkIndex", type: .uint256, indexed: true),
    SolidityEvent.Parameter(name: "value", type: .uint256, indexed: false),
    SolidityEvent.Parameter(name: "fromAddress", type: .address, indexed: true)
  ])
  
  private var name = "CryptoPunks"
  
  let contractAddressHex = "0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb"
  private let initFromBlock : BigUInt
  private var punksBoughtLogs : LogsFetcher
  private var punksOfferedLogs : LogsFetcher
  
  
  class EthContract : EthereumContract {
    let eth = ETHEREUM_WEB3.eth
    let events : [SolidityEvent] = []
    let addressHex = "0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb"
    var address : EthereumAddress?
    init() {
      address = try? EthereumAddress(hex:addressHex, eip55: false)
    }
    
    func punkIndexToAddress(_ tokenId:BigUInt) -> Promise<EthereumAddress> {
      let inputs = [SolidityFunctionParameter(name: "tokenId", type: .uint256)]
      let outputs = [SolidityFunctionParameter(name: "address", type: .address)]
      let method = SolidityConstantFunction(name: "punkIndexToAddress", inputs: inputs, outputs: outputs, handler: self)
      print("calling punkIndexToAddress")
      return
        method.invoke(tokenId).call()
        .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs in
          return outputs["address"] as! EthereumAddress
        }
    }
    
    func punksOfferedForSale(_ tokenId:BigUInt) -> Promise<BigUInt?> {
      let inputs = [SolidityFunctionParameter(name: "tokenId", type: .uint256)]
      
      let outputs = [
        SolidityFunctionParameter(name: "isForSale", type: .bool),
        SolidityFunctionParameter(name: "punkIndex", type: .uint256),
        SolidityFunctionParameter(name: "seller", type: .address),
        SolidityFunctionParameter(name: "minValue", type: .uint256),
        SolidityFunctionParameter(name: "onlySellTo", type: .address)
      ]
      let method = SolidityConstantFunction(name: "punksOfferedForSale", inputs: inputs, outputs: outputs, handler: self)
      print("calling punksOfferedForSale")
      return
        method.invoke(tokenId).call()
        .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs in
          return outputs["isForSale"] as! Bool ? (outputs["minValue"] as? BigUInt).flatMap(priceIfNotZero) : nil
        }
    }
    
    func punkBids(_ tokenId:BigUInt) -> Promise<BigUInt?> {
      let inputs = [SolidityFunctionParameter(name: "tokenId", type: .uint256)]
      
      let outputs = [
        SolidityFunctionParameter(name: "hasBid", type: .bool),
        SolidityFunctionParameter(name: "punkIndex", type: .uint256),
        SolidityFunctionParameter(name: "bidder", type: .address),
        SolidityFunctionParameter(name: "value", type: .uint256)
      ]
      let method = SolidityConstantFunction(name: "punkBids", inputs: inputs, outputs: outputs, handler: self)
      print("calling punkBids")
      return
        method.invoke(tokenId).call()
        .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs in
          return outputs["hasBid"] as! Bool ? (outputs["value"] as? BigUInt).flatMap(priceIfNotZero) : nil
        }
    }
    
    func enterBidForPunk(tokenId: BigUInt,wei:BigUInt,from:EthereumAddress) -> EthereumTransaction {
      // function enterBidForPunk(uint punkIndex) payable {
      
      let inputs = [SolidityFunctionParameter(name: "punkIndex", type: .uint256)]
      let method = SolidityPayableFunction(name: "enterBidForPunk", inputs: inputs, outputs: [], handler: self)
      
      return method.invoke(tokenId).createTransaction(
        nonce: nil,
        from: from,
        value:EthereumQuantity(quantity: wei),
        gas: 200000,
        gasPrice: nil)!
    }
    
    func buyPunk(tokenId: BigUInt,wei:BigUInt,from:EthereumAddress) -> EthereumTransaction {
      //  function buyPunk(uint punkIndex) payable {
      
      let inputs = [SolidityFunctionParameter(name: "punkIndex", type: .uint256)]
      let method = SolidityPayableFunction(name: "buyPunk", inputs: inputs, outputs: [], handler: self)
      
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
                                      ethContract.enterBidForPunk(tokenId:BigUInt(tokenId),wei: wei,from: wallet.account))
    }
    
    func acceptOffer(tokenId: UInt, wei: BigUInt, wallet: WalletProvider) -> Promise<EthereumTransactionReceiptObject> {
      print("submitting buyPunk")
      return wallet.sendTransaction(tx:
                                      ethContract.buyPunk(tokenId:BigUInt(tokenId),wei: wei,from: wallet.account))
    }
  }
  
  struct TradeInterface : TokenTradeInterface {
    
    var actions: TradeActionsInterface? {
      return TradeActions(ethContract: ethContract)
    }
    
    let ethContract : EthContract
    
    func getBidAsk(_ tokenId: UInt) -> Promise<BidAsk> {
      
      ethContract.punkBids(BigUInt(tokenId))
        .then { bidPrice in
          ethContract.punksOfferedForSale(BigUInt(tokenId))
            .map { askPrice in
              return BidAsk(
                bid:bidPrice.map { BidInfo(wei:$0) },
                ask:askPrice.map { AskInfo(wei:$0) }
              )
            }
        }
    }
  }
  
  var tradeActions: TokenTradeInterface?
  
  init () {
    initFromBlock = (UserDefaults.standard.string(forKey: "\(contractAddressHex).initFromBlock").flatMap { BigUInt($0)}) ?? INIT_BLOCK
    punksBoughtLogs = LogsFetcher(event:PunkBought,fromBlock:initFromBlock,address:contractAddressHex,indexedTopics: [],blockDecrements: nil)
    punksOfferedLogs = LogsFetcher(event:PunkOffered,fromBlock:initFromBlock,address:contractAddressHex,indexedTopics: [],blockDecrements: nil)
    tradeActions = TradeInterface(ethContract:ethContract)
  }
  
  private func imageUrl(_ tokenId:UInt) -> URL? {
    return URL(string:"https://www.larvalabs.com/public/images/cryptopunks/punk\(String(format: "%04d", Int(tokenId))).png")
  }
  
  private func eventOfTx(transactionHash:EthereumData?,eventType:TradeEventType) -> Promise<TradeEvent?> {
    
    txFetcher.eventOfTx(transactionHash: transactionHash)
      .map(on:DispatchQueue.global(qos:.userInteractive)) { (txData:TxFetcher.TxInfo?) in
        switch(txData) {
        case .none: return nil
        case .some(let tx):
          return TradeEvent(type:eventType,value:tx.value,blockNumber:tx.blockNumber)
        }
      }
  }
  
  private func onTradeLog(tokenId:BigUInt,logValue:BigUInt?,type:TradeEventType,blockNumber:BigUInt?,transactionHash:EthereumData?,
                          _ response: @escaping (NFTWithPrice) -> Void) {
    switch (logValue) {
    case .some (let value):
      response(NFTWithPrice(
        nft:NFT(
          address:self.contractAddressHex,
          tokenId:UInt(tokenId),
          name:self.name,
          media:.image(MediaImageEager(self.imageUrl(UInt(tokenId))!))),
        blockNumber: blockNumber,
        indicativePriceWei:.eager(
          NFTPriceInfo(
            price:value,
            blockNumber: blockNumber,
            type:type))
      ))
    case .none:
      response(NFTWithPrice(
        nft:NFT(
          address:self.contractAddressHex,
          tokenId:UInt(tokenId),
          name:self.name,
          media:.image(MediaImageEager(self.imageUrl(UInt(tokenId))!))),
        blockNumber: blockNumber,
        indicativePriceWei:.lazy {
          ObservablePromise(
            promise:
              self.eventOfTx(transactionHash:transactionHash,eventType:type)
              .map {
                let price = priceIfNotZero($0?.value);
                return NFTPriceStatus.known(
                  NFTPriceInfo(
                    price:price,
                    blockNumber:blockNumber,
                    type: price.map { _ in type } ?? TradeEventType.transfer))
              }
          )
        }
      ))
    }
  }
  
  func getRecentTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
    
    var fetchers = 2
    
    punksBoughtLogs.fetch(onDone:{
      fetchers-=1
      if (fetchers < 1) { onDone() }
    }) { log in
      let res = try! Web3ABI.decodeLog(event:self.PunkBought,from:log)
      self.onTradeLog(
        tokenId:res["punkIndex"] as! BigUInt,
        logValue:priceIfNotZero(res["value"] as? BigUInt),
        type:.bought,
        blockNumber:log.blockNumber?.quantity,
        transactionHash:log.transactionHash,
        response)
    }
    punksOfferedLogs.fetch(onDone: {
      fetchers-=1
      if (fetchers < 1) { onDone() }
    }) { log in
      let res = try! Web3ABI.decodeLog(event:self.PunkOffered,from:log)
      self.onTradeLog(
        tokenId:res["punkIndex"] as! BigUInt,
        logValue:priceIfNotZero(res["minValue"] as? BigUInt),
        type:.ask,
        blockNumber:log.blockNumber?.quantity,
        transactionHash:log.transactionHash,
        response)
    }
  }
  
  func refreshLatestTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
    
    var fetchers = 2
    
    punksBoughtLogs.updateLatest(onDone:{
      fetchers-=1
      if (fetchers < 1) { onDone() }
    }) { index,log in
      let res = try! Web3ABI.decodeLog(event:self.PunkBought,from:log)
      self.onTradeLog(
        tokenId:res["punkIndex"] as! BigUInt,
        logValue:priceIfNotZero(res["value"] as? BigUInt),
        type:.bought,
        blockNumber:log.blockNumber?.quantity,
        transactionHash:log.transactionHash,
        response)
    }
    
    punksOfferedLogs.updateLatest(onDone:{
      fetchers-=1
      if (fetchers < 1) { onDone() }
    }) { index,log in
      let res = try! Web3ABI.decodeLog(event:self.PunkOffered,from:log)
      self.onTradeLog(
        tokenId:res["punkIndex"] as! BigUInt,
        logValue:priceIfNotZero(res["minValue"] as? BigUInt),
        type:.ask,
        blockNumber:log.blockNumber?.quantity,
        transactionHash:log.transactionHash,
        response)
    }
    
  }
  
  private func getTokenHistory(_ tokenId: UInt,punkBoughtFetcher:LogsFetcher,punkOfferedFetcher:LogsFetcher,retries:UInt) -> Promise<TradeEventStatus> {
    var events : [TradeEvent] = []
    return Promise { seal in
      punkBoughtFetcher.fetch(onDone:{seal.fulfill(events)}) { log in
        let res = try! Web3ABI.decodeLog(event:self.PunkBought,from:log);
        log.blockNumber.map { blockNumber in
          events.append(TradeEvent(type: .bought, value: res["value"] as! BigUInt, blockNumber:blockNumber))
        }
      }
    }.then(on:DispatchQueue.global(qos:.userInteractive)) { boughtEvents -> Promise<[TradeEvent]> in
      var events = boughtEvents
      return Promise { seal in
        punkOfferedFetcher.fetch(onDone:{seal.fulfill(events)}) { log in
          //print(log);
          let res = try! Web3ABI.decodeLog(event:self.PunkOffered,from:log);
          log.blockNumber.map { blockNumber in
            events.append(TradeEvent(type: .ask, value: res["minValue"] as! BigUInt, blockNumber:blockNumber))
          }
        }
      }
    }.compactMap(on:DispatchQueue.global(qos:.userInteractive)) { events in
      events.sorted(by: { $0.blockNumber.quantity > $1.blockNumber.quantity})
    }.then(on:DispatchQueue.global(qos:.userInteractive)) { events -> Promise<TradeEventStatus> in
      switch(events.count,retries) {
      case (0,0):
        return Promise.value(
          TradeEventStatus.notSeenSince(
            NFTNotSeenSince(
              blockNumber: min(
                punkBoughtFetcher.fromBlock,
                punkOfferedFetcher.fromBlock
              )
            )
          )
        )
      case (0,_):
        return self.getTokenHistory(tokenId,punkBoughtFetcher:punkBoughtFetcher,punkOfferedFetcher:punkOfferedFetcher,retries:retries-1)
      default:
        // TODO : Pick value from tx
        return Promise.value(TradeEventStatus.trade(events.first!))
      }
    }
  }
  
  func getNFT(_ tokenId: UInt) -> NFT {
    NFT(
      address:self.contractAddressHex,
      tokenId:tokenId,
      name:self.name,
      media:.image(MediaImageEager(self.imageUrl(tokenId)!)))
  }
  
  func getToken(_ tokenId: UInt) -> NFTWithLazyPrice {
    NFTWithLazyPrice(
      nft:getNFT(tokenId),
      getPrice: {
        
        switch(self.pricesCache[tokenId]) {
        case .some(let p):
          return p
        case .none:
          let tokenIdTopic = try! ABI.encodeParameter(SolidityWrappedValue.uint(BigUInt(tokenId)))
          let punkBoughtFetcher = LogsFetcher(
            event:self.PunkBought,
            fromBlock:self.initFromBlock,
            address:self.contractAddressHex,
            indexedTopics: [tokenIdTopic],
            blockDecrements: 10000)
          
          let punkOfferedFetcher = LogsFetcher(
            event:self.PunkOffered,
            fromBlock:self.initFromBlock,
            address:self.contractAddressHex,
            indexedTopics: [tokenIdTopic],
            blockDecrements: 10000)
          
          let p =
            self.getTokenHistory(tokenId,punkBoughtFetcher:punkBoughtFetcher,punkOfferedFetcher:punkOfferedFetcher,retries:30)
            .map(on:DispatchQueue.global(qos:.userInteractive)) { (event:TradeEventStatus) -> NFTPriceStatus in
              switch(event) {
              case .trade(let event):
                return NFTPriceStatus.known(NFTPriceInfo(price:priceIfNotZero(event.value),blockNumber:event.blockNumber.quantity,type:event.type))
              case .notSeenSince(let since):
                return NFTPriceStatus.notSeenSince(since)
              }
            }
          let observable = ObservablePromise(promise:p)
          DispatchQueue.main.async {
            self.pricesCache[tokenId] = observable
          }
          return observable
        }
      }
    )
  }
  
  
  class EventsFetcher : TokenEventsFetcher {
    private let PunkBought: SolidityEvent = SolidityEvent(name: "PunkBought", anonymous: false, inputs: [
      SolidityEvent.Parameter(name: "punkIndex", type: .uint256, indexed: true),
      SolidityEvent.Parameter(name: "value", type: .uint256, indexed: false),
      SolidityEvent.Parameter(name: "fromAddress", type: .address, indexed: true),
      SolidityEvent.Parameter(name: "toAddress", type: .address, indexed: true)
    ])
    
    private let PunkOffered: SolidityEvent = SolidityEvent(name: "PunkOffered", anonymous: false, inputs: [
      SolidityEvent.Parameter(name: "punkIndex", type: .uint256, indexed: true),
      SolidityEvent.Parameter(name: "minValue", type: .uint256, indexed: false),
      SolidityEvent.Parameter(name: "toAddress", type: .address, indexed: true)
    ])
    
    private let PunkBidEntered: SolidityEvent = SolidityEvent(name: "PunkBidEntered", anonymous: false, inputs: [
      SolidityEvent.Parameter(name: "punkIndex", type: .uint256, indexed: true),
      SolidityEvent.Parameter(name: "value", type: .uint256, indexed: false),
      SolidityEvent.Parameter(name: "fromAddress", type: .address, indexed: true)
    ])
    
    private var punkBoughtFetcher : LogsFetcher
    private var punkOfferedFetcher : LogsFetcher
    private var punkBidFetcher : LogsFetcher
    init(punkBoughtFetcher:LogsFetcher,punkOfferedFetcher:LogsFetcher,punkBidFetcher:LogsFetcher) {
      self.punkBoughtFetcher = punkBoughtFetcher
      self.punkOfferedFetcher = punkOfferedFetcher
      self.punkBidFetcher = punkBidFetcher
    }
    
    func getEvents(onDone: @escaping () -> Void,_ response: @escaping (TradeEvent) -> Void) {
      var counter = 0
      
      punkBoughtFetcher.fetchAllLogs(onDone: {
        counter+=1
        if (counter >= 3) { onDone() }
      }) { log in
        let res = try! Web3ABI.decodeLog(event:self.PunkBought,from:log);
        
        let from = res["fromAddress"] as! EthereumAddress
        var type : TradeEventType = .bought
        
        if (from == EthereumAddress(hexString: "0x0000000000000000000000000000000000000000")) {
          type = .minted
        }
        response(TradeEvent(type:type, value: res["value"] as! BigUInt, blockNumber:log.blockNumber!))
      }
      
      punkOfferedFetcher.fetchAllLogs(onDone: {
        counter+=1
        if (counter >= 3) { onDone() }
      }) { log in
        let res = try! Web3ABI.decodeLog(event:self.PunkOffered,from:log);
        response(TradeEvent(type:.ask, value: res["minValue"] as! BigUInt, blockNumber:log.blockNumber!))
      }
      
      punkBidFetcher.fetchAllLogs(onDone: {
        counter+=1
        if (counter >= 3) { onDone() }
      }) { log in
        let res = try! Web3ABI.decodeLog(event:self.PunkBidEntered,from:log);
        response(TradeEvent(type:.bid, value: res["value"] as! BigUInt, blockNumber:log.blockNumber!))
      }
    }
    
  }
  
  func getEventsFetcher(_ tokenId: UInt) -> TokenEventsFetcher? {
    let tokenIdTopic = try! ABI.encodeParameter(SolidityWrappedValue.uint(BigUInt(tokenId)))
    let punkBoughtFetcher = LogsFetcher(
      event:self.PunkBought,
      fromBlock:self.initFromBlock,
      address:self.contractAddressHex,
      indexedTopics: [tokenIdTopic],
      blockDecrements: 10000)
    
    let punkOfferedFetcher = LogsFetcher(
      event:self.PunkOffered,
      fromBlock:self.initFromBlock,
      address:self.contractAddressHex,
      indexedTopics: [tokenIdTopic],
      blockDecrements: 10000)
    
    let punkBidFetcher = LogsFetcher(
      event:self.PunkBidEntered,
      fromBlock:self.initFromBlock,
      address:self.contractAddressHex,
      indexedTopics: [tokenIdTopic],
      blockDecrements: 10000)
    
    return EventsFetcher(punkBoughtFetcher:punkBoughtFetcher,punkOfferedFetcher:punkOfferedFetcher,punkBidFetcher:punkBidFetcher)
  }
  
  struct Asset: Codable {
    var token_id : String
  }
  
  struct OwnerAssets: Codable {
    var assets: [Asset]
  }
  
  private func getOwnerTokensFromOpenSea(address:EthereumAddress) -> Promise<[UInt]> {
    return Promise { seal in
      var request = URLRequest(url: URL(string: "https://api.opensea.io/api/v1/assets?owner=\(address.hex(eip55: false))&asset_contract_address=\(contractAddressHex)")!)
      request.httpMethod = "GET"
      
      print("calling \(request.url!)")
      URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
        do {
          let jsonDecoder = JSONDecoder()
          let assets = try jsonDecoder.decode(OwnerAssets.self, from: data!)
          seal.fulfill(assets.assets.map { UInt($0.token_id)! })
        } catch {
          print("JSON Serialization error:\(error), json=\(data.map { String(decoding: $0, as: UTF8.self) } ?? "")")
          seal.fulfill([])
        }
      }).resume()
    }
  }
  
  
  func getOwnerTokens(address: EthereumAddress, onDone: @escaping () -> Void, _ response: @escaping (NFTWithLazyPrice) -> Void) {
    getOwnerTokensFromOpenSea(address:address)
      .map(on:DispatchQueue.global(qos:.userInteractive)) { (tokenIds:[UInt]) -> [Void] in
        return tokenIds.map { response(self.getToken($0)) }
      }.done(on:DispatchQueue.global(qos:.userInteractive)) { (promises:[Void]) -> Void in
        onDone()
      }.catch {
        print ($0)
        onDone()
      }
  }
  
  func ownerOf(_ tokenId: UInt) -> Promise<EthereumAddress?> {
    return ethContract.punkIndexToAddress(BigUInt(tokenId)).map { addressIfNotZero($0) }
  }
  
}
