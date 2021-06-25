//
//  CryptoPunksContract.swift
//  NFTY
//
//  Created by Varun Kohli on 4/22/21.
//

import Foundation

import Cache

import Web3
import Web3PromiseKit
import Web3ContractABI

public struct EthereumGetLogParams: Codable {
  public var fromBlock: EthereumQuantityTag?
  public var toBlock: EthereumQuantityTag?
  public var address: EthereumAddress?
  public var topics:[String?]
}

extension Web3.Eth {
  public typealias Web3ResponseCompletion<Result: Codable> = (_ resp: Web3Response<Result>) -> Void
  public func getLogs(
    params: EthereumGetLogParams,
    response: @escaping Web3ResponseCompletion<[EthereumLogObject]>
  ) {
    let req = RPCRequest<[EthereumGetLogParams]>(
      id: properties.rpcId,
      jsonrpc: Web3.jsonrpc,
      method: "eth_getLogs",
      params: [params]
    )
    properties.provider.send(request: req, response: response)
  }
}

func addressIfNotZero(_ address:EthereumAddress) -> EthereumAddress? {
  // print(address.hex(eip55: false))
  if (address == EthereumAddress(hexString: "0x0000000000000000000000000000000000000000")) {
    return nil
  } else {
    return .some(address)
  }
}

class TxFetcher {
  
  struct TxInfo : Codable {
    var value : BigUInt
    var blockNumber : EthereumQuantity
  }
  
  private var txCache = try! DiskStorage<EthereumData, TxInfo>(
    config: DiskConfig(name: "TxFetcher.txCache",expiry: .never),
    transformer: TransformerFactory.forCodable(ofType: TxInfo.self))
  
  private func eventOfTx(transactionHash:EthereumData) -> Promise<TxInfo?> {
    web3.eth.getTransactionByHash(blockHash:transactionHash)
      .map(on:DispatchQueue.global(qos:.userInteractive)) { (txData:EthereumTransactionObject?) in
        switch(txData) {
        case .none: return nil
        case .some(let tx):
          switch(tx.value.quantity,tx.blockNumber) {
          case (_,.none): return nil
          case (let value,.some(let blockNumber)):
            return TxInfo(value:value,blockNumber: blockNumber)
          }
        }
      }
  }
  
  func eventOfTx(transactionHash:EthereumData?) -> Promise<TxInfo?> {
    switch transactionHash {
    case .none:
      return Promise.value(nil)
    case .some(let txHash):
      switch (try? txCache.object(forKey:txHash)) {
      case .some(let p):
        return Promise.value(p)
      case .none:
        let p = eventOfTx(transactionHash: txHash)
        p.done {
          $0.flatMap { try? self.txCache.setObject($0, forKey: txHash) }
        }.catch { print($0) }
        return p
      }
    }
  }
}

var txFetcher = TxFetcher()


var web3 = Web3(rpcURL: "https://mainnet.infura.io/v3/b4287cfd0a6b4849bd0ca79e144d3921")
var INIT_BLOCK = BigUInt(12642194)

protocol ContractInterface {
  
  var contractAddressHex: String { get }
  func getRecentTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void)
  func refreshLatestTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void)
  func getToken(_ tokenId:UInt) -> Promise<NFTWithLazyPrice>
  func ownerOf(_ tokenId:UInt) -> Promise<EthereumAddress?>
  func getOwnerTokens(address:EthereumAddress,onDone: @escaping () -> Void,_ response: @escaping (NFTWithLazyPrice) -> Void)
}

func priceIfNotZero(_ price:BigUInt?) -> BigUInt? {
  return price.flatMap { $0 != 0 ? $0 : nil }
}

class LogsFetcher {
  private let blockDecrements : BigUInt
  private let searchBlocks : BigUInt
  private var toBlock = EthereumQuantityTag.latest
  private var mostRecentBlock = EthereumQuantityTag.latest
  
  let event : SolidityEvent
  var fromBlock : BigUInt
  var address : String
  var topics : [String?]
  
  init(event:SolidityEvent,fromBlock:BigUInt,address:String,indexedTopics:[String?]) {
    self.event = event;
    self.fromBlock = fromBlock;
    self.address = address
    self.topics = [
      web3.eth.abi.encodeEventSignature(self.event)
    ]
    self.topics.append(contentsOf: indexedTopics)
    self.searchBlocks = 500
    self.blockDecrements = searchBlocks * 4
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
  
  private var name = "CryptoPunks"
  
  let contractAddressHex = "0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb"
  private let initFromBlock : BigUInt
  private var punksBoughtLogs : LogsFetcher
  
  
  class EthContract : EthereumContract {
    let eth = web3.eth
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
      return
        method.invoke(tokenId).call()
        .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs in
          return outputs["address"] as! EthereumAddress
        }
    }
  }
  private var ethContract = EthContract()
  
  init () {
    initFromBlock = (UserDefaults.standard.string(forKey: "\(contractAddressHex).initFromBlock").flatMap { BigUInt($0)}) ?? INIT_BLOCK
    punksBoughtLogs = LogsFetcher(event:PunkBought,fromBlock:initFromBlock,address:contractAddressHex,indexedTopics: [])
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
  
  func getRecentTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
    return punksBoughtLogs.fetch(onDone:onDone) { log in
      
      let res = try! web3.eth.abi.decodeLog(event:self.PunkBought,from:log)
      let tokenId = UInt(res["punkIndex"] as! BigUInt)
      let logValue = priceIfNotZero(res["value"] as? BigUInt)
      switch (logValue) {
      case .some (let value):
        response(NFTWithPrice(
          nft:NFT(
            address:self.contractAddressHex,
            tokenId:tokenId,
            name:self.name,
            media:.image(MediaImageEager(self.imageUrl(tokenId)!))),
          indicativePriceWei:
            NFTPriceInfo(
              price:value,
              blockNumber: log.blockNumber?.quantity)
        ))
      case .none:
        let onPrice = { (indicativePriceWei:BigUInt?) in
          response(NFTWithPrice(
            nft:NFT(
              address:self.contractAddressHex,
              tokenId:tokenId,
              name:self.name,
              media:.image(MediaImageEager(self.imageUrl(tokenId)!))),
            indicativePriceWei:
              NFTPriceInfo(
                price:priceIfNotZero(indicativePriceWei),
                blockNumber: log.blockNumber?.quantity)
          ))
        }
        
        self.eventOfTx(transactionHash:log.transactionHash,eventType:.bought)
          .done(on:DispatchQueue.global(qos:.userInteractive)) {
            onPrice($0?.value)
          }.catch { error in
            print(error);
            onPrice(nil)
          }
      }
    }
  }
  
  func refreshLatestTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
    return punksBoughtLogs.updateLatest(onDone:onDone) { log in
      
      let res = try! web3.eth.abi.decodeLog(event:self.PunkBought,from:log);
      let tokenId = UInt(res["punkIndex"] as! BigUInt)
      let logValue = priceIfNotZero(res["value"] as? BigUInt)
      switch (logValue) {
      case .some (let value):
        response(NFTWithPrice(
          nft:NFT(
            address:self.contractAddressHex,
            tokenId:tokenId,
            name:self.name,
            media:.image(MediaImageEager(self.imageUrl(tokenId)!))),
          indicativePriceWei:
            NFTPriceInfo(
              price:value,
              blockNumber: log.blockNumber?.quantity)
        ))
      case .none:
        let onPrice = { (indicativePriceWei:BigUInt?) in
          response(NFTWithPrice(
            nft:NFT(
              address:self.contractAddressHex,
              tokenId:tokenId,
              name:self.name,
              media:.image(MediaImageEager(self.imageUrl(tokenId)!))),
            indicativePriceWei:
              NFTPriceInfo(
                price:priceIfNotZero(indicativePriceWei),
                blockNumber: log.blockNumber?.quantity)
          ))
        }
        
        self.eventOfTx(transactionHash:log.transactionHash,eventType:.bought)
          .done(on:DispatchQueue.global(qos:.userInteractive)) {
            onPrice($0?.value)
          }.catch { error in
            print(error);
            onPrice(nil)
          }
      }
    }
  }
  
  private func getTokenHistory(_ tokenId: UInt,punkBoughtFetcher:LogsFetcher,punkOfferedFetcher:LogsFetcher,retries:UInt) -> Promise<TradeEventStatus> {
    var events : [TradeEvent] = []
    return Promise { seal in
      punkBoughtFetcher.fetch(onDone:{seal.fulfill(events)}) { log in
        let res = try! web3.eth.abi.decodeLog(event:self.PunkBought,from:log);
        log.blockNumber.map { blockNumber in
          events.append(TradeEvent(type: .bought, value: res["value"] as! BigUInt, blockNumber:blockNumber))
        }
      }
    }.then(on:DispatchQueue.global(qos:.userInteractive)) { boughtEvents -> Promise<[TradeEvent]> in
      var events = boughtEvents
      return Promise { seal in
        punkOfferedFetcher.fetch(onDone:{seal.fulfill(events)}) { log in
          //print(log);
          let res = try! web3.eth.abi.decodeLog(event:self.PunkOffered,from:log);
          log.blockNumber.map { blockNumber in
            events.append(TradeEvent(type: .offer, value: res["minValue"] as! BigUInt, blockNumber:blockNumber))
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
  
  func getToken(_ tokenId: UInt) -> Promise<NFTWithLazyPrice> {
    
    Promise.value(
      NFTWithLazyPrice(
        nft:NFT(
          address:self.contractAddressHex,
          tokenId:tokenId,
          name:self.name,
          media:.image(MediaImageEager(self.imageUrl(tokenId)!))),
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
              indexedTopics: [tokenIdTopic])
            
            let punkOfferedFetcher = LogsFetcher(
              event:self.PunkOffered,
              fromBlock:self.initFromBlock,
              address:self.contractAddressHex,
              indexedTopics: [tokenIdTopic])
            
            let p =
              self.getTokenHistory(tokenId,punkBoughtFetcher:punkBoughtFetcher,punkOfferedFetcher:punkOfferedFetcher,retries:30)
              .map(on:DispatchQueue.global(qos:.userInteractive)) { (event:TradeEventStatus) -> NFTPriceStatus in
                switch(event) {
                case .trade(let event):
                  return NFTPriceStatus.known(NFTPriceInfo(price:priceIfNotZero(event.value),blockNumber:event.blockNumber.quantity))
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
    );
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
      .then(on:DispatchQueue.global(qos:.userInteractive)) { (tokenIds:[UInt]) -> Promise<Void> in
        return when(
          fulfilled:tokenIds.map { self.getToken($0).done { response($0) } }
        )
      }.done(on:DispatchQueue.global(qos:.userInteractive)) { (promises:Void) -> Void in
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

class CryptoKittiesAuction : ContractInterface {
  
  private var pricesCache : [UInt : ObservablePromise<NFTPriceStatus>] = [:]
  private var imagesCache : [BigUInt : ObservablePromise<URL>] = [:]
  
  private let AuctionSuccessful: SolidityEvent = SolidityEvent(name: "AuctionSuccessful", anonymous: false, inputs: [
    SolidityEvent.Parameter(name: "tokenId", type: .uint256, indexed: false),
    SolidityEvent.Parameter(name: "totalPrice", type: .uint256, indexed: false),
    SolidityEvent.Parameter(name: "winner", type: .address, indexed: false)
  ])
  
  struct Kitty: Codable {
    var id : UInt
    var image_url_png: String
  }
  
  struct KittiesByWallet: Codable {
    var kitties: [Kitty]
  }
  
  class SaleAuctionContract : EthereumContract {
    let eth = web3.eth
    let events : [SolidityEvent] = []
    let addressHex = "0xb1690C08E213a35Ed9bAb7B318DE14420FB57d8C"
    var address : EthereumAddress?
    init() {
      address = try? EthereumAddress(hex:addressHex, eip55: false)
    }
  }
  
  class EthContract : EthereumContract {
    let eth = web3.eth
    let events : [SolidityEvent] = []
    let addressHex = "0x06012c8cf97BEaD5deAe237070F9587f8E7A266d"
    var address : EthereumAddress?
    init() {
      address = try? EthereumAddress(hex:addressHex, eip55: false)
    }
    
    func tokensOfOwner(address:EthereumAddress) -> Promise<[BigUInt]> {
      let inputs = [SolidityFunctionParameter(name: "owner", type: .address)]
      let outputs = [SolidityFunctionParameter(name: "tokens", type: .array(type: .uint256, length: nil))]
      let method = SolidityConstantFunction(name: "tokensOfOwner", inputs: inputs, outputs: outputs, handler: self)
      return
        method.invoke(address).call()
        .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs in
          return outputs["tokens"] as! [BigUInt]
        }
    }
    
    func kittyIndexToOwner(_ tokenId:BigUInt) -> Promise<EthereumAddress> {
      let inputs = [SolidityFunctionParameter(name: "tokenId", type: .uint256)]
      let outputs = [SolidityFunctionParameter(name: "address", type: .address)]
      let method = SolidityConstantFunction(name: "kittyIndexToOwner", inputs: inputs, outputs: outputs, handler: self)
      return
        method.invoke(tokenId).call()
        .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs in
          return outputs["address"] as! EthereumAddress
        }
    }
    
  }
  private var ethContract = EthContract()
  
  private var name = "CryptoKitties"
  let contractAddressHex = "0x06012c8cf97BEaD5deAe237070F9587f8E7A266d"
  private let saleAuctionContract = SaleAuctionContract()
  
  private var auctionSuccessfulFetcher : LogsFetcher
  private let initFromBlock : BigUInt
  
  init () {
    initFromBlock = (UserDefaults.standard.string(forKey: "\(contractAddressHex).initFromBlock").flatMap { BigUInt($0)}) ?? INIT_BLOCK
    auctionSuccessfulFetcher = LogsFetcher(event:AuctionSuccessful,fromBlock:initFromBlock,address:saleAuctionContract.addressHex,indexedTopics: [])
  }
  
  private func getOwnerKitties(address:EthereumAddress) -> Promise<KittiesByWallet> {
    
    // https://public.api.cryptokitties.co/v1/kitties?owner_wallet_address=0x007880443b595eb375ab6b6566ad9a52630659ff
    
    return Promise { seal in
      var request = URLRequest(url: URL(string: "https://public.api.cryptokitties.co/v1/kitties?owner_wallet_address=\(address.hex(eip55: false))")!)
      request.httpMethod = "GET"
      request.addValue("Uci2BC2E8vloA_Lmm43gGPXtXhvrSu6AYbac5GmTGy8",forHTTPHeaderField:"x-api-token")
      
      
      URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
        do {
          let jsonDecoder = JSONDecoder()
          let kitties = try jsonDecoder.decode(KittiesByWallet.self, from: data!)
          seal.fulfill(kitties)
        } catch {
          print("JSON Serialization error:\(error), json=\(data.map { String(decoding: $0, as: UTF8.self) } ?? "")")
          seal.fulfill(KittiesByWallet(kitties: []))
        }
      }).resume()
    }
  }
  
  
  
  private func getKitty(tokenId:BigUInt) -> Promise<Kitty> {
    return Promise { seal in
      var request = URLRequest(url: URL(string: "https://public.api.cryptokitties.co/v1/kitties/\(tokenId)")!)
      request.httpMethod = "GET"
      request.addValue("Uci2BC2E8vloA_Lmm43gGPXtXhvrSu6AYbac5GmTGy8",forHTTPHeaderField:"x-api-token")
      
      
      URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
        do {
          let jsonDecoder = JSONDecoder()
          let kittyInfo = try jsonDecoder.decode(Kitty.self, from: data!)
          seal.fulfill(kittyInfo)
        } catch {
          print("JSON Serialization error:\(error), json=\(data.map { String(decoding: $0, as: UTF8.self) } ?? "" )")
          seal.reject(error)
        }
      }).resume()
    }
  }
  
  private func getMediaImage(_ tokenId:BigUInt) -> MediaImageLazy {
    return MediaImageLazy(get: {
      switch (self.imagesCache[tokenId]) {
      case .some(let p):
        return p
      case .none:
        let p = self.getKitty(tokenId:tokenId)
          .compactMap(on:DispatchQueue.global(qos:.userInteractive)) { kitty -> URL in
            return URL(string:kitty.image_url_png)!
          }
        let observable = ObservablePromise(promise: p)
        DispatchQueue.main.async {
          self.imagesCache[tokenId] = observable
        }
        return observable
      }
    })
  }
  
  func getRecentTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
    return auctionSuccessfulFetcher.fetch(onDone:onDone) { log in
      let res = try! web3.eth.abi.decodeLog(event:self.AuctionSuccessful,from:log);
      let tokenId = res["tokenId"] as! BigUInt;
      response(NFTWithPrice(
        nft:NFT(
          address:self.contractAddressHex,
          tokenId:UInt(tokenId),
          name:self.name,
          media:.image(self.getMediaImage(tokenId))),
        indicativePriceWei:NFTPriceInfo(
          price: priceIfNotZero(res["totalPrice"] as? BigUInt),
          blockNumber: log.blockNumber?.quantity)
      ))
    }
  }
  
  func refreshLatestTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
    return auctionSuccessfulFetcher.updateLatest(onDone:onDone) { log in
      let res = try! web3.eth.abi.decodeLog(event:self.AuctionSuccessful,from:log);
      let tokenId = res["tokenId"] as! BigUInt;
      response(NFTWithPrice(
        nft:NFT(
          address:self.contractAddressHex,
          tokenId:UInt(tokenId),
          name:self.name,
          media:.image(self.getMediaImage(tokenId))),
        indicativePriceWei:NFTPriceInfo(
          price: priceIfNotZero(res["totalPrice"] as? BigUInt),
          blockNumber: log.blockNumber?.quantity)
      ))
    }
  }
  
  private func getTokenHistory(_ tokenId: UInt,fetcher:LogsFetcher,retries:UInt) -> Promise<TradeEventStatus> {
    var events : [TradeEvent] = []
    return Promise { seal in
      fetcher.fetch(onDone:{seal.fulfill(events)}) { log in
        let res = try! web3.eth.abi.decodeLog(event:self.AuctionSuccessful,from:log);
        log.blockNumber.map { blockNumber in
          // CryptoKitties does not index logs, so we filter here
          if (res["tokenId"] as! BigUInt == BigUInt(tokenId)) {
            events.append(TradeEvent(type: .bought, value: res["totalPrice"] as! BigUInt, blockNumber:blockNumber))
          }
        }
      }
    }
    .compactMap(on:DispatchQueue.global(qos:.userInteractive)) { events in
      events.sorted(by: { $0.blockNumber.quantity > $1.blockNumber.quantity})
    }.then(on:DispatchQueue.global(qos:.userInteractive)) { events -> Promise<TradeEventStatus> in
      switch(events.count,retries) {
      case (0,0):
        return Promise.value(
          TradeEventStatus.notSeenSince(
            NFTNotSeenSince(
              blockNumber:fetcher.fromBlock
            )
          )
        )
      case (0,_):
        return self.getTokenHistory(tokenId,fetcher:fetcher,retries:retries-1)
      default:
        return Promise.value(TradeEventStatus.trade(events.first!))
      }
    }
  }
  
  func getToken(_ tokenId: UInt) -> Promise<NFTWithLazyPrice> {
    return Promise.value(NFTWithLazyPrice(
      nft:NFT(
        address:self.contractAddressHex,
        tokenId:UInt(tokenId),
        name:self.name,
        media:.image(getMediaImage(BigUInt(tokenId)))),
      getPrice: {
        switch(self.pricesCache[tokenId]) {
        case .some(let p):
          return p
        case .none:
          let auctionDoneFetcher = LogsFetcher(
            event:self.AuctionSuccessful,
            fromBlock:self.initFromBlock,
            address:self.saleAuctionContract.addressHex,
            indexedTopics: [])
          let p =
            self.getTokenHistory(tokenId,fetcher:auctionDoneFetcher,retries:10)
            .map { (event:TradeEventStatus) -> NFTPriceStatus in
              switch(event) {
              case .trade(let event):
                return NFTPriceStatus.known(NFTPriceInfo(price:priceIfNotZero(event.value),blockNumber:event.blockNumber.quantity))
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
    ))
  }
  
  func getOwnerTokens(address: EthereumAddress, onDone: @escaping () -> Void, _ response: @escaping (NFTWithLazyPrice) -> Void) {
    self.getOwnerKitties(address: address)
      .then(on:DispatchQueue.global(qos:.userInteractive)) { (kitties:KittiesByWallet) -> Promise<Void> in
        return when(
          fulfilled:
            kitties.kitties.map { kitty in
              self.getToken(kitty.id).done {
                response($0)
              }
            }
        )
      }.catch {
        print ($0)
      }
  }
  
  func ownerOf(_ tokenId: UInt) -> Promise<EthereumAddress?> {
    return ethContract.kittyIndexToOwner(BigUInt(tokenId)).map { addressIfNotZero($0) }
  }
}

class AsciiPunksContract : ContractInterface {
  
  private var drawingCache = try! DiskStorage<BigUInt, Media.AsciiPunk>(
    config: DiskConfig(name: "AsciiPunksDrawingsCache",expiry: .never),
    transformer: TransformerFactory.forCodable(ofType: Media.AsciiPunk.self))
  
  private var pricesCache : [UInt : ObservablePromise<NFTPriceStatus>] = [:]
  
  private let Transfer: SolidityEvent = SolidityEvent(name: "Transfer", anonymous: false, inputs: [
    SolidityEvent.Parameter(name: "from", type: .address, indexed: true),
    SolidityEvent.Parameter(name: "from", type: .address, indexed: true),
    SolidityEvent.Parameter(name: "tokenId", type: .uint256, indexed: true),
  ])
  
  private var name = "AsciiPunks"
  
  let contractAddressHex = "0x5283Fc3a1Aac4DaC6B9581d3Ab65f4EE2f3dE7DC"
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
      return
        method.invoke(tokenId).call()
        .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs in
          return outputs["address"] as! EthereumAddress
        }
    }
    
  }
  private var ethContract = EthContract()
  
  init () {
    initFromBlock = (UserDefaults.standard.string(forKey: "\(contractAddressHex).initFromBlock").flatMap { BigUInt($0)}) ?? INIT_BLOCK
    transfer = LogsFetcher(event:Transfer,fromBlock:initFromBlock,address:contractAddressHex,indexedTopics: [])
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
          return TradeEvent(type:eventType,value:tx.value,blockNumber:tx.blockNumber)
        }
      }
  }
  
  func getRecentTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
    return transfer.fetch(onDone:onDone,retries:10) { log in
      let res = try! web3.eth.abi.decodeLog(event:self.Transfer,from:log);
      let tokenId = UInt(res["tokenId"] as! BigUInt);
      
      let onPrice = { (indicativePriceWei:BigUInt?) in
        response(NFTWithPrice(
          nft:NFT(
            address:self.contractAddressHex,
            tokenId:tokenId,
            name:self.name,
            media:.asciiPunk(Media.AsciiPunkLazy(tokenId:BigUInt(tokenId), draw: self.draw))),
          indicativePriceWei:NFTPriceInfo(
            price:priceIfNotZero(indicativePriceWei),
            blockNumber:log.blockNumber?.quantity)
        ))
      };
      
      self.eventOfTx(transactionHash:log.transactionHash,eventType:.bought)
        .done(on:DispatchQueue.global(qos:.userInteractive)) {
          onPrice($0?.value)
        }.catch { error in
          print(error);
          onPrice(nil)
        }
    }
  }
  
  func refreshLatestTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
    return transfer.updateLatest(onDone:onDone) { log in
      let res = try! web3.eth.abi.decodeLog(event:self.Transfer,from:log);
      let tokenId = UInt(res["tokenId"] as! BigUInt);
      
      let onPrice = { (indicativePriceWei:BigUInt?) in
        response(NFTWithPrice(
          nft:NFT(
            address:self.contractAddressHex,
            tokenId:tokenId,
            name:self.name,
            media:.asciiPunk(Media.AsciiPunkLazy(tokenId:BigUInt(tokenId), draw: self.draw))),
          indicativePriceWei:NFTPriceInfo(
            price:priceIfNotZero(indicativePriceWei),
            blockNumber:log.blockNumber?.quantity)
        ))
      };
      
      self.eventOfTx(transactionHash:log.transactionHash,eventType:.bought)
        .done(on:DispatchQueue.global(qos:.userInteractive)) {
          onPrice($0?.value)
        }.catch { error in
          print(error);
          onPrice(nil)
        }
    }
  }
  
  private func getTokenHistory(_ tokenId: UInt,fetcher:LogsFetcher,retries:UInt) -> Promise<TradeEventStatus> {
    var events : [Promise<TradeEvent?>] = []
    return Promise { seal in
      fetcher.fetch(onDone:{
        when(fulfilled:events)
          .done(on:DispatchQueue.global(qos:.userInteractive)) { events in
            seal.fulfill(events.filter { $0 != nil }.map { $0! })
          }.catch {
            print ($0)
            seal.fulfill([])
          }
      }) { log in
        events.append(self.eventOfTx(transactionHash:log.transactionHash,eventType:.bought))
      }
    }
    .compactMap(on:DispatchQueue.global(qos:.userInteractive)) { events in
      events.sorted(by: { $0.blockNumber.quantity > $1.blockNumber.quantity})
    }.then(on:DispatchQueue.global(qos:.userInteractive)) { events -> Promise<TradeEventStatus> in
      switch(events.count,retries) {
      case (0,0):
        return Promise.value(
          TradeEventStatus.notSeenSince(
            NFTNotSeenSince(
              blockNumber:fetcher.fromBlock
            )
          )
        )
      case (0,_):
        return self.getTokenHistory(tokenId,fetcher:fetcher,retries:retries-1)
      default:
        return Promise.value(TradeEventStatus.trade(events.first!))
      }
    }
  }
  
  func getToken(_ tokenId: UInt) -> Promise<NFTWithLazyPrice> {
    
    Promise.value(
      NFTWithLazyPrice(
        nft:NFT(
          address:self.contractAddressHex,
          tokenId:tokenId,
          name:self.name,
          media:.asciiPunk(Media.AsciiPunkLazy(tokenId:BigUInt(tokenId), draw: self.draw))),
        getPrice: {
          switch(self.pricesCache[tokenId]) {
          case .some(let p):
            return p
          case .none:
            let tokenIdTopic = try! ABI.encodeParameter(SolidityWrappedValue.uint(BigUInt(tokenId)))
            let transerFetcher = LogsFetcher(
              event:self.Transfer,
              fromBlock:self.initFromBlock,
              address:self.contractAddressHex,
              indexedTopics: [nil,nil,tokenIdTopic])
            
            let p =
              self.getTokenHistory(tokenId,fetcher:transerFetcher,retries:30)
              .map(on:DispatchQueue.global(qos:.userInteractive)) { (event:TradeEventStatus) -> NFTPriceStatus in
                switch(event) {
                case .trade(let event):
                  return NFTPriceStatus.known(NFTPriceInfo(price:priceIfNotZero(event.value),blockNumber:event.blockNumber.quantity))
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
    );
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
                  .then { tokenId in
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
  
}


class AutoglyphsContract : ContractInterface {
  
  private var drawingCache = try! DiskStorage<BigUInt, Media.Autoglyph>(
    config: DiskConfig(name: "AutoglyphsDrawingsCache",expiry: .never),
    transformer: TransformerFactory.forCodable(ofType: Media.Autoglyph.self))
  
  private var pricesCache : [UInt : ObservablePromise<NFTPriceStatus>] = [:]
  
  private var name = "Autoglyph"
  
  let contractAddressHex = "0xd4e4078ca3495DE5B1d4dB434BEbc5a986197782"
  
  class DrawEthContract : EthereumContract {
    let eth = web3.eth
    let events : [SolidityEvent] = []
    var address : EthereumAddress?
    init(_ addressHex:String) {
      address = try? EthereumAddress(hex:addressHex, eip55: false)
    }
    
    func draw(_ tokenId:BigUInt) -> Promise<Media.Autoglyph?> {
      let inputs = [SolidityFunctionParameter(name: "tokenId", type: .uint256)]
      let outputs = [SolidityFunctionParameter(name: "uri", type: .string)]
      let method = SolidityConstantFunction(name: "draw", inputs: inputs, outputs: outputs, handler: self)
      return
        method.invoke(tokenId).call()
        .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs in
          return Media.Autoglyph(utf8:outputs["uri"] as! String)
        }
    }
    
  }
  
  class GlyphContract : Erc721Contract {
    
    let drawContract : DrawEthContract
    
    init(contractAddress:String) {
      self.drawContract = DrawEthContract(contractAddress)
      super.init(address:contractAddress)
    }
  }
  
  private var ethContract = GlyphContract(contractAddress:"0xd4e4078ca3495DE5B1d4dB434BEbc5a986197782")
  
  private func draw(_ tokenId:BigUInt) -> ObservablePromise<Media.Autoglyph?> {
    switch(try? drawingCache.object(forKey:tokenId)) {
    case .some(let p):
      return ObservablePromise(resolved: p)
    case .none:
      
      let p = ethContract.drawContract.draw(tokenId);
      let observable = ObservablePromise(promise: p) { drawing in
        drawing.flatMap {
          try? self.drawingCache.setObject($0, forKey: tokenId)
        }
      }
      return observable
    }
  }
  
  func getRecentTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
    return ethContract.transfer.fetch(onDone:onDone,retries:10) { log in
      let res = try! web3.eth.abi.decodeLog(event:self.ethContract.Transfer,from:log);
      let tokenId = UInt(res["tokenId"] as! BigUInt);
      
      let onPrice = { (indicativePriceWei:BigUInt?) in
        response(NFTWithPrice(
          nft:NFT(
            address:self.contractAddressHex,
            tokenId:tokenId,
            name:self.name,
            media:.autoglyph(Media.AutoglyphLazy(tokenId:BigUInt(tokenId), draw: self.draw))),
          indicativePriceWei:NFTPriceInfo(
            price:priceIfNotZero(indicativePriceWei),
            blockNumber:log.blockNumber?.quantity)
        ))
      };
      
      self.ethContract.eventOfTx(transactionHash:log.transactionHash,eventType:.bought)
        .done(on:DispatchQueue.global(qos:.userInteractive)) {
          onPrice($0?.value)
        }.catch { error in
          print(error);
          onPrice(nil)
        }
    }
  }
  
  func refreshLatestTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
    return ethContract.transfer.updateLatest(onDone:onDone) { log in
      let res = try! web3.eth.abi.decodeLog(event:self.ethContract.Transfer,from:log);
      let tokenId = UInt(res["tokenId"] as! BigUInt);
      
      let onPrice = { (indicativePriceWei:BigUInt?) in
        response(NFTWithPrice(
          nft:NFT(
            address:self.contractAddressHex,
            tokenId:tokenId,
            name:self.name,
            media:.autoglyph(Media.AutoglyphLazy(tokenId:BigUInt(tokenId), draw: self.draw))),
          indicativePriceWei:NFTPriceInfo(
            price:priceIfNotZero(indicativePriceWei),
            blockNumber:log.blockNumber?.quantity)
        ))
      };
      
      self.ethContract.eventOfTx(transactionHash:log.transactionHash,eventType:.bought)
        .done(on:DispatchQueue.global(qos:.userInteractive)) {
          onPrice($0?.value)
        }.catch { error in
          print(error);
          onPrice(nil)
        }
    }
  }
  
  func getToken(_ tokenId: UInt) -> Promise<NFTWithLazyPrice> {
    
    Promise.value(
      NFTWithLazyPrice(
        nft:NFT(
          address:self.contractAddressHex,
          tokenId:tokenId,
          name:self.name,
          media:.autoglyph(Media.AutoglyphLazy(tokenId:BigUInt(tokenId), draw: self.draw))),
        getPrice: {
          switch(self.ethContract.pricesCache[tokenId]) {
          case .some(let p):
            return p
          case .none:
            let tokenIdTopic = try! ABI.encodeParameter(SolidityWrappedValue.uint(BigUInt(tokenId)))
            let transerFetcher = LogsFetcher(
              event:self.ethContract.Transfer,
              fromBlock:self.ethContract.initFromBlock,
              address:self.contractAddressHex,
              indexedTopics: [nil,nil,tokenIdTopic])
            
            let p =
              self.ethContract.getTokenHistory(tokenId,fetcher:transerFetcher,retries:30)
              .map(on:DispatchQueue.global(qos:.userInteractive)) { (event:TradeEventStatus) -> NFTPriceStatus in
                switch(event) {
                case .trade(let event):
                  return NFTPriceStatus.known(NFTPriceInfo(price:priceIfNotZero(event.value),blockNumber:event.blockNumber.quantity))
                case .notSeenSince(let since):
                  return NFTPriceStatus.notSeenSince(since)
                }
              }
            let observable = ObservablePromise(promise: p)
            DispatchQueue.main.async {
              self.ethContract.pricesCache[tokenId] = observable
            }
            return observable
          }
        }
      )
    );
  }
  
  func getOwnerTokens(address: EthereumAddress, onDone: @escaping () -> Void, _ response: @escaping (NFTWithLazyPrice) -> Void) {
    ethContract.ethContract.balanceOf(address:address)
      .then(on:DispatchQueue.global(qos: .userInteractive)) { tokensNum -> Promise<Void> in
        if (tokensNum <= 0) {
          return Promise.value(())
        } else {
          return when(
            fulfilled:
              Array(0...tokensNum-1).map { index -> Promise<Void> in
                return
                  self.ethContract.ethContract.tokenOfOwnerByIndex(address: address,index:index)
                  .then { tokenId in
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
    return ethContract.ownerOf(tokenId)
  }
  
}



class BlockFetcherImpl {
  
  private var blocksCache = try! DiskStorage<EthereumQuantityTag, EthereumBlockObject>(
    config: DiskConfig(name: "BlockFetcherCache",expiry: .never),
    transformer: TransformerFactory.forCodable(ofType: EthereumBlockObject.self))
  
  func getBlock(blockNumber:EthereumQuantityTag) -> ObservablePromise<EthereumBlockObject?> {
    switch(try? blocksCache.object(forKey:blockNumber)) {
    case .some(let p):
      return ObservablePromise(resolved: p)
    case .none:
      let p = web3.eth.getBlockByNumber(block:blockNumber, fullTransactionObjects: false)
      return ObservablePromise(promise: p) { block in
        block.flatMap { try? self.blocksCache.setObject($0, forKey: blockNumber) }
      }
    }
  }
  
}

var BlocksFetcher = BlockFetcherImpl()


class UserEthRate {
  private var cache : Promise<Double?>? = nil
  
  struct SpotResponse : Decodable {
    struct SpotData : Decodable {
      let base : String
      let currency : String
      let amount : String
    }
    let data : SpotData
  }
  
  private func getRate() -> Promise<Double?> {
    switch(NSLocale.current.currencyCode) {
    case .none:
      return Promise.value(nil)
    case .some(let localCurrencyCode):
      return Promise { seal in
        var request = URLRequest(url: URL(string: "https://api.coinbase.com/v2/prices/ETH-\(localCurrencyCode)/spot")!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
          do {
            let jsonDecoder = JSONDecoder()
            let response = try jsonDecoder.decode(SpotResponse.self, from: data!)
            seal.fulfill(Double(response.data.amount))
          } catch {
            print("JSON Serialization error:\(error), json=\(data.map { String(decoding: $0, as: UTF8.self) } ?? "" )")
            seal.fulfill(nil)
          }
        }).resume()
      }
    }
  }
  
  func get() -> Promise<Double?> {
    switch(self.cache) {
    case .some(let p):
      return p
    case .none:
      let p = getRate()
      DispatchQueue.main.async {
        self.cache = p
      }
      return p
    }
  }
  
}

var EthSpot = UserEthRate()
