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
import CloudKit

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
    let from: EthereumAddress
    let value : BigUInt
    let blockNumber : EthereumQuantity
  }
  
  static private func eventOfTx(_ transactionHash:EthereumData) -> Promise<EthereumTransactionObject?> {
    print("getTransactionByHash \(transactionHash.hex())");
    return web3.eth.getTransactionByHash(blockHash:transactionHash)
      .map(on:DispatchQueue.global(qos:.userInitiated)) { (txData:EthereumTransactionObject?) -> EthereumTransactionObject? in
        switch(txData?.blockNumber) {
        case .none: return nil
        case .some: return txData
        }
      }
  }
  
#if os(macOS)
  static func eventOfTx(transactionHash:EthereumData?) -> Promise<TxInfo?> {
    // print("Getting eventOfTx for \(transactionHash?.hex() ?? "")")
    switch transactionHash {
    case .none:
      return Promise.value(nil)
    case .some(let txHash):
      return TxFetcher.eventOfTx(txHash)
        .map {
          guard let tx = $0 else { return nil }
          guard let blockNumber = tx.blockNumber else { return nil }
          return TxInfo(from:tx.from,value:tx.value.quantity,blockNumber: blockNumber)
          
        }
    }
  }
#else
  private static var cache = CKObjectCache(
    database: CKPublicDataManager.defaultContainer.publicCloudDatabase,
    entityName: "EthereumTransactionData",
    keyField: "txHash",
    fallback: { (txHash:EthereumData,output:EthereumTransactionData) in
      return TxFetcher.eventOfTx(txHash)
        .map {
          guard let tx = $0 else { return nil }
          let key = txHash.hex()
          output.txHash = tx.hash.hex()
          output.from = tx.from.hex(eip55: true)
          output.to = tx.to?.hex(eip55: true)
          output.value = tx.value.hex()
          output.blockNumber = tx.blockNumber?.hex()
          return output
        }
    },
    keyToString: { $0.hex() }
  )
  
  static func eventOfTx(transactionHash:EthereumData?) -> Promise<TxInfo?> {
    // print("Getting eventOfTx for \(transactionHash?.hex() ?? "")")
    switch transactionHash {
    case .none:
      return Promise.value(nil)
    case .some(let txHash):
      return cache.get(txHash)
        .map(on:DispatchQueue.global(qos:.userInitiated)) { (txData:EthereumTransactionData?) -> TxInfo? in
          switch(txData) {
          case .none:
            return nil
          case .some(let tx):
            guard let blockNumber = (tx.blockNumber.flatMap { try? EthereumQuantity.string($0) }) else { return nil }
            guard let value = (tx.value.flatMap { try? EthereumQuantity.string($0) }) else { return nil }
            guard let from = (tx.from.flatMap { try? EthereumAddress(hex: $0, eip55: true) }) else { return nil }
            return TxInfo(from:from,value:value.quantity,blockNumber: blockNumber)
          }
        }
    }
  }
#endif
  
}

class WETHFetcher {
  
  struct Info : Codable {
    var value : BigUInt
    var blockNumber : EthereumQuantity
  }
  
  private var cache = try! DiskStorage<EthereumData, Info>(
    config: DiskConfig(name: "WETHFetcher.cache2",expiry: .never),
    transformer: TransformerFactory.forCodable(ofType: Info.self))
  
  private func valueOfTx(transactionHash:EthereumData) -> Promise<Info?> {
    print("getTransactionReceipt for \(transactionHash.hex())");
    return web3.eth.getTransactionReceipt(transactionHash: transactionHash)
      .map(on:DispatchQueue.global(qos:.userInitiated)) { (txData:EthereumTransactionReceiptObject?) -> Info? in
        switch(txData) {
        case .none:
          return nil
        case .some(let tx):
          let sum = tx.logs
            .compactMap { log in
              if (log.address.hex(eip55:false) != WETH_ADDRESS) {
                return nil
              }
              
              if (!log.topics.contains(
                try! EthereumData.string(
                  "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef")
              )) {
                return nil
              }
              
              return try! web3.eth.abi.decodeParameter(type:SolidityType.uint256,from:log.data.hex()) as! BigUInt
            }
            .reduce(BigUInt(0),+)
          return Info(value:sum,blockNumber: tx.blockNumber)
        }
      }
  }
  
  func valueOfTx(transactionHash:EthereumData?) -> Promise<Info?> {
    switch transactionHash {
    case .none:
      return Promise.value(nil)
    case .some(let txHash):
      return Promise { seal in
        DispatchQueue.global(qos:.userInteractive).async {
          switch (try? self.cache.object(forKey:txHash)) {
          case .some(let p):
            seal.fulfill(p)
          case .none:
            let p = self.valueOfTx(transactionHash: txHash)
            p.done(on:DispatchQueue.global(qos:.userInteractive)) {
              $0.flatMap { try? self.cache.setObject($0, forKey: txHash) }
              seal.fulfill($0)
            }
            .catch {
              print($0)
              seal.fulfill(nil)
            }
          }
        }
      }
    }
  }
}

var wethFetcher = WETHFetcher()

var alchemyWeb3 = Web3(
  provider: Web3HttpProviderWithRetry(
    rpcURL: "https://eth-mainnet.alchemyapi.io/v2/StghaadzMZpTbz5As9hHcmEMxl5Hcflc"))

/* var web3 = Web3(
 provider: Web3HttpProvider(
 rpcURL: "https://mainnet.infura.io/v3/b4287cfd0a6b4849bd0ca79e144d3921"))
 */
var web3 = alchemyWeb3

var INIT_BLOCK = BigUInt(13972779 - (Date.from(year:2022,month:1,day:9)!.timeIntervalSinceNow / 15))

protocol TokenEventsFetcher {
  func getEvents(onDone: @escaping () -> Void,_ response: @escaping (TradeEvent) -> Void)
}

func priceIfNotZero(_ price:BigUInt?) -> BigUInt? {
  return price.flatMap { $0 != 0 ? $0 : nil }
}

func priceIfNotZero(_ price:PriceUnit?) -> BigUInt? {
  switch(price) {
  case .some(.wei(0)):
    return nil
  case .some(.near(0)):
    return nil
  case .none:
    return nil
  case .some(.wei(let x)):
    return x
  case .some(.near(let x)):
    return x
  }
}


class CryptoKittiesAuction : ContractInterface {
  func floorFetcher(_ collection:Collection) -> PagedTokensFetcher? { return nil }
  
  var vaultContract: CollectionVaultContract? = nil
  
  var tradeActions: TokenTradeInterface? = nil
  
  func getEventsFetcher(_ tokenId: BigUInt) -> TokenEventsFetcher? { return nil }
  
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
      print("calling tokensOfOwner")
      return method.invoke(address).call()
        .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs in
          return outputs["tokens"] as! [BigUInt]
        }
    }
    
    func kittyIndexToOwner(_ tokenId:BigUInt) -> Promise<EthereumAddress> {
      let inputs = [SolidityFunctionParameter(name: "tokenId", type: .uint256)]
      let outputs = [SolidityFunctionParameter(name: "address", type: .address)]
      let method = SolidityConstantFunction(name: "kittyIndexToOwner", inputs: inputs, outputs: outputs, handler: self)
      print("calling kittyIndexToOwner")
      return method.invoke(tokenId).call()
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
    auctionSuccessfulFetcher = LogsFetcher(event:AuctionSuccessful,fromBlock:initFromBlock,address:saleAuctionContract.addressHex,indexedTopics: [],blockDecrements: nil)
  }
  
  private func getOwnerKitties(address:EthereumAddress) -> Promise<KittiesByWallet> {
    
    // https://public.api.cryptokitties.co/v1/kitties?owner_wallet_address=0x007880443b595eb375ab6b6566ad9a52630659ff
    
    return Promise { seal in
      var request = URLRequest(url: URL(string: "https://public.api.cryptokitties.co/v1/kitties?owner_wallet_address=\(address.hex(eip55: false))")!)
      request.httpMethod = "GET"
      request.addValue("Uci2BC2E8vloA_Lmm43gGPXtXhvrSu6AYbac5GmTGy8",forHTTPHeaderField:"x-api-token")
      
      print("calling \(request.url!)")
      ImageLoadingSemaphore.wait()
      URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
        ImageLoadingSemaphore.signal()
        if let e = error { return seal.reject(e) }
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
      
      print("calling \(request.url!)")
      ImageLoadingSemaphore.wait()
      URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
        ImageLoadingSemaphore.signal()
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
          tokenId:tokenId,
          name:self.name,
          media:.image(self.getMediaImage(tokenId))),
        blockNumber:log.blockNumber.map { .ethereum($0) },
        indicativePrice:.eager(NFTPriceInfo(
          wei: priceIfNotZero(res["totalPrice"] as? BigUInt),
          blockNumber:log.blockNumber.map { .ethereum($0) },
          type: priceIfNotZero(res["totalPrice"] as? BigUInt) == nil ? .transfer : .bought))
      ))
    }
  }
  
  func refreshLatestTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
    return auctionSuccessfulFetcher.updateLatest(onDone:onDone) { index,log in
      let res = try! web3.eth.abi.decodeLog(event:self.AuctionSuccessful,from:log);
      let tokenId = res["tokenId"] as! BigUInt;
      response(NFTWithPrice(
        nft:NFT(
          address:self.contractAddressHex,
          tokenId:tokenId,
          name:self.name,
          media:.image(self.getMediaImage(tokenId))),
        blockNumber:log.blockNumber.map { .ethereum($0) },
        indicativePrice:.eager(NFTPriceInfo(
          wei: priceIfNotZero(res["totalPrice"] as? BigUInt),
          blockNumber:log.blockNumber.map { .ethereum($0) },
          type: priceIfNotZero(res["totalPrice"] as? BigUInt) == nil ? .transfer : .bought))
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
            events.append(TradeEvent(type: .bought, value: .wei(res["totalPrice"] as! BigUInt), blockNumber:.ethereum(blockNumber)))
          }
        }
      }
    }
    .compactMap(on:DispatchQueue.global(qos:.userInteractive)) { events in
      events.sorted(by: { $0.blockNumber > $1.blockNumber})
    }.then(on:DispatchQueue.global(qos:.userInteractive)) { events -> Promise<TradeEventStatus> in
      switch(events.count,retries) {
      case (0,0):
        return Promise.value(
          TradeEventStatus.notSeenSince(
            NFTNotSeenSince(
              blockNumber:.ethereum(EthereumQuantity(quantity: fetcher.fromBlock))
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
  
  func getNFT(_ tokenId: BigUInt) -> NFT {
    NFT(
      address:self.contractAddressHex,
      tokenId:tokenId,
      name:self.name,
      media:.image(getMediaImage(tokenId)))
  }
  
  
  func getToken(_ tokenId: UInt) -> NFTWithLazyPrice {
    NFTWithLazyPrice(
      nft:getNFT(BigUInt(tokenId)),
      getPrice: {
        switch(self.pricesCache[tokenId]) {
        case .some(let p):
          return p
        case .none:
          let auctionDoneFetcher = LogsFetcher(
            event:self.AuctionSuccessful,
            fromBlock:self.initFromBlock,
            address:self.saleAuctionContract.addressHex,
            indexedTopics: [],
            blockDecrements: 5000)
          let p =
          self.getTokenHistory(tokenId,fetcher:auctionDoneFetcher,retries:10)
            .map { (event:TradeEventStatus) -> NFTPriceStatus in
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
    self.getOwnerKitties(address: address)
      .map(on:DispatchQueue.global(qos:.userInteractive)) { (kitties:KittiesByWallet) -> [Void] in
        return kitties.kitties.map { kitty in
          response(self.getToken(kitty.id))
        }
      }.catch { print ($0) }
      .finally { onDone() }
  }
  
  func ownerOf(_ tokenId: BigUInt) -> Promise<UserAccount?> {
    return ethContract.kittyIndexToOwner(tokenId).map { addressIfNotZero($0) }
      .map { $0.map { UserAccount(ethAddress: $0, nearAccount: nil) } }
  }
  
  func indicativeFloor() -> Promise<PriceUnit?> { return Promise.value(nil) }
  
}


class AutoglyphsContract : ContractInterface {
  
  private var drawingCache = try! DiskStorage<BigUInt, Media.Autoglyph>(
    config: DiskConfig(name: "AutoglyphsDrawingsCache",expiry: .never),
    transformer: TransformerFactory.forCodable(ofType: Media.Autoglyph.self))
  
  private var pricesCache : [UInt : ObservablePromise<NFTPriceStatus>] = [:]
  
  private var name = "Autoglyph"
  
  let contractAddressHex = "0xd4e4078ca3495DE5B1d4dB434BEbc5a986197782"
#if os(macOS)
  var tradeActions: TokenTradeInterface? = nil
#else
  var tradeActions: TokenTradeInterface? = OpenSeaTradeApi(contract: try!
                                                           EthereumAddress(hex: "0xd4e4078ca3495DE5B1d4dB434BEbc5a986197782", eip55: false))
#endif
  
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
      print("calling draw")
      return method.invoke(tokenId).call()
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
  
  func getEventsFetcher(_ tokenId: BigUInt) -> TokenEventsFetcher? { return ethContract.getEventsFetcher(tokenId) }
  
  
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
    return try! ethContract.transfer.wait().fetch(onDone:onDone,retries:10) { log in
      let res = try! web3.eth.abi.decodeLog(event:Erc721Contract.Transfer,from:log);
      let tokenId = res["tokenId"] as! BigUInt
      
      response(NFTWithPrice(
        nft:NFT(
          address:self.contractAddressHex,
          tokenId:tokenId,
          name:self.name,
          media:.autoglyph(Media.AutoglyphLazy(tokenId:tokenId, draw: self.draw))),
        blockNumber:log.blockNumber.map { .ethereum($0) },
        indicativePrice:.lazy {
          ObservablePromise(
            promise:
              self.ethContract.eventOfTx(transactionHash:log.transactionHash,eventType:.bought)
              .map {
                let price = priceIfNotZero($0?.value);
                return NFTPriceStatus.known(
                  NFTPriceInfo(
                    wei:price,
                    blockNumber:log.blockNumber.map { .ethereum($0) },
                    type: price.map { _ in TradeEventType.bought } ?? TradeEventType.transfer))
              }
          )
        }
      ))
    }
  }
  
  func refreshLatestTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
    return try! ethContract.transfer.wait().updateLatest(onDone:onDone) { index,log in
      let res = try! web3.eth.abi.decodeLog(event:Erc721Contract.Transfer,from:log);
      let tokenId = res["tokenId"] as! BigUInt
      
      response(NFTWithPrice(
        nft:NFT(
          address:self.contractAddressHex,
          tokenId:tokenId,
          name:self.name,
          media:.autoglyph(Media.AutoglyphLazy(tokenId:tokenId, draw: self.draw))),
        blockNumber:log.blockNumber.map { .ethereum($0) },
        indicativePrice:.lazy {
          ObservablePromise(
            promise:
              self.ethContract.eventOfTx(transactionHash:log.transactionHash,eventType:.bought)
              .map {
                let price = priceIfNotZero($0?.value);
                return NFTPriceStatus.known(
                  NFTPriceInfo(
                    wei:price,
                    blockNumber:log.blockNumber.map { .ethereum($0) },
                    type: price.map { _ in TradeEventType.bought } ?? TradeEventType.transfer))
              }
          )
        }
      ))
    }
  }
  
  func getNFT(_ tokenId: BigUInt) -> NFT {
    NFT(
      address:self.contractAddressHex,
      tokenId:tokenId,
      name:self.name,
      media:.autoglyph(Media.AutoglyphLazy(tokenId:tokenId, draw: self.draw)))
  }
  
  func getToken(_ tokenId: UInt) -> NFTWithLazyPrice {
    NFTWithLazyPrice(
      nft:getNFT(BigUInt(tokenId)),
      getPrice: {
        switch(self.ethContract.pricesCache[tokenId]) {
        case .some(let p):
          return p
        case .none:
          let p =
          self.ethContract.getTokenHistory(tokenId)
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
            self.ethContract.pricesCache[tokenId] = observable
          }
          return observable
        }
      }
    )
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
                return self.ethContract.ethContract.tokenOfOwnerByIndex(address: address,index:index)
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
  
  func ownerOf(_ tokenId: BigUInt) -> Promise<UserAccount?> {
    return ethContract.ownerOf(tokenId)
  }
  
  func indicativeFloor() -> Promise<PriceUnit?> {
    return SushiSwapPool(address:"0x0d9f9c919f1b66a8587a5637b8d1a6a6c5854380").priceInEthRev()
  }
  
  var vaultContract : CollectionVaultContract? = CollectionVaultContract(address:"0xD70240Dd62F4ea9a6A2416e0073D72139489d2AA")
  
  func floorFetcher(_ collection:Collection) -> PagedTokensFetcher? {
    return OpenSeaFloorFetcher.make(collection: collection)
  }
  
}



class BlockFetcherImpl {
  
  struct BlockInfo : Codable {
    let timestamp : Date
  }
  
  private var blocksCache = try! DiskStorage<BlockNumber, BlockInfo>(
    config: DiskConfig(name: "BlockFetcherImplCache",expiry: .never),
    transformer: TransformerFactory.forCodable(ofType: BlockInfo.self))
  
  private func getEthereumBlock(blockNumber:EthereumQuantity) -> ObservablePromise<BlockInfo?> {
    return ObservablePromise(
      promise: Promise { seal in
        DispatchQueue.global(qos:.userInteractive).async {
          switch(try? self.blocksCache.object(forKey:.ethereum(blockNumber))) {
          case .some(let p):
            seal.fulfill(p)
          case .none:
            print("getBlockByNumber")
            web3.eth.getBlockByNumber(block:.block(blockNumber.quantity), fullTransactionObjects: false)
              .done(on:DispatchQueue.global(qos:.userInteractive)) {
                seal.fulfill(($0?.timestamp).map {
                  BlockInfo(timestamp:Date(timeIntervalSince1970:Double($0.quantity)))
                })
              }
              .catch {
                print($0)
                seal.fulfill(nil)
              }
          }
        }
      }
    ) { block in
      block.flatMap { try? self.blocksCache.setObject($0, forKey: .ethereum(blockNumber)) }
    }
  }
  
  private func getNearBlock(blockHeight:EthereumQuantity) -> ObservablePromise<BlockInfo?> {
    
    return ObservablePromise(
      promise: Promise { seal in
        DispatchQueue.global(qos:.userInteractive).async {
          switch(try? self.blocksCache.object(forKey:.near(blockHeight))) {
          case .some(let p):
            seal.fulfill(p)
          case .none:
            NearApi.block(block_id: blockHeight.quantity)
              .done(on:DispatchQueue.global(qos:.userInteractive)) {
                seal.fulfill(
                  $0.map {
                    BlockInfo(timestamp:Date(timeIntervalSince1970:(Double($0.header.timestamp) / Double(1e9))))
                  }
                )
              }
              .catch {
                print($0)
                seal.fulfill(nil)
              }
          }
        }
      }
    ) { block in
      block.flatMap { try? self.blocksCache.setObject($0, forKey: .near(blockHeight)) }
    }
  }
  
  func getBlock(blockNumber:BlockNumber) -> ObservablePromise<BlockInfo?> {
    switch(blockNumber) {
    case .ethereum(let blockNumber):
      return self.getEthereumBlock(blockNumber: blockNumber)
    case .near(let blockHeight):
      return self.getNearBlock(blockHeight:blockHeight)
    }
  }
  
}

var BlocksFetcher = BlockFetcherImpl()

let ImageLoadingSemaphore = DispatchSemaphore(value: 2)

class UserEthRate {
  private var cache : ObservablePromise<Double?>? = nil
  
  struct SpotResponse : Decodable {
    struct SpotData : Decodable {
      let base : String
      let currency : String
      let amount : String
    }
    let data : SpotData
  }
  
  static func getLiveRate() -> Promise<Double?> {
    print("Getting spot")
    switch(NSLocale.current.currencyCode) {
    case .none:
      return Promise.value(nil)
    case .some(let localCurrencyCode):
      return Promise { seal in
        guard let url = URL(string: "https://api.coinbase.com/v2/prices/ETH-\(localCurrencyCode)/spot") else {
          seal.fulfill(nil); return
        }
        var request = URLRequest(url:url)
        request.httpMethod = "GET"
        
        print("Calling coinbae api for \(localCurrencyCode)")
        ImageLoadingSemaphore.wait()
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
          ImageLoadingSemaphore.signal()
          print("Got response from coinbase")
          guard let data = data else {
            print("Empty data calling \(url), error=\(String(describing: error))")
            seal.fulfill(nil)
            return
          }
          do {
            let jsonDecoder = JSONDecoder()
            let response = try jsonDecoder.decode(SpotResponse.self, from: data)
            seal.fulfill(Double(response.data.amount))
          } catch {
            print("JSON Serialization error:\(error), json=\(String(decoding:data, as: UTF8.self))")
            seal.fulfill(nil)
          }
        }).resume()
      }
    }
  }
  
  func get() -> ObservablePromise<Double?> {
    switch(self.cache) {
    case .some(let p):
      return p
    case .none:
      let p = ObservablePromise(promise: UserEthRate.getLiveRate())
      self.cache = p
      return p
    }
  }
  
}

var EthSpot = UserEthRate()

func ipfsUrl(_ url:String) -> String {
  
  _ = "https://cloudflare-ipfs.com/ipfs/"
  let infura = "https://ipfs.infura.io:5001/api/v0/cat?arg="
  let ipfsProvider = infura
  return url
    .replacingOccurrences(of: "ipfs://",with: ipfsProvider)
    .replacingOccurrences(of: "https://ipfs.io/ipfs/",with: ipfsProvider)
    .replacingOccurrences(of: "https://gateway.pinata.cloud/ipfs/",with: ipfsProvider)
}
