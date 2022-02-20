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
    print("calling web3.eth.getLogs")
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
    print("getTransactionByHash");
    return web3.eth.getTransactionByHash(blockHash:transactionHash)
      .map(on:DispatchQueue.global(qos:.userInitiated)) { (txData:EthereumTransactionObject?) -> TxInfo? in
        switch(txData) {
        case .none:
          return nil
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
      return Promise { seal in
        DispatchQueue.global(qos:.userInteractive).async {
          switch (try? self.txCache.object(forKey:txHash)) {
          case .some(let p):
            seal.fulfill(p)
          case .none:
            let p = self.eventOfTx(transactionHash: txHash)
            p.done(on:DispatchQueue.global(qos:.userInteractive)) {
              $0.flatMap { try? self.txCache.setObject($0, forKey: txHash) }
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

var txFetcher = TxFetcher()

class WETHFetcher {
  
  struct Info : Codable {
    var value : BigUInt
    var blockNumber : EthereumQuantity
  }
  
  private var cache = try! DiskStorage<EthereumData, Info>(
    config: DiskConfig(name: "WETHFetcher.cache",expiry: .never),
    transformer: TransformerFactory.forCodable(ofType: Info.self))
  
  private func valueOfTx(transactionHash:EthereumData) -> Promise<Info?> {
    print("getTransactionReceipt");
    return web3.eth.getTransactionReceipt(transactionHash: transactionHash)
      .map(on:DispatchQueue.global(qos:.userInitiated)) { (txData:EthereumTransactionReceiptObject?) -> Info? in
        switch(txData) {
        case .none:
          return nil
        case .some(let tx):
          return tx.logs
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
              
              // Get data for the log
            }
            .first
            .map { Info(value:$0,blockNumber: tx.blockNumber) }
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


var web3 = Web3(rpcURL: "https://mainnet.infura.io/v3/b4287cfd0a6b4849bd0ca79e144d3921")
var INIT_BLOCK = BigUInt(13972779 - (Date.from(year:2022,month:1,day:9)!.timeIntervalSinceNow / 15))

protocol TokenEventsFetcher {
  func getEvents(onDone: @escaping () -> Void,_ response: @escaping (TradeEvent) -> Void)
}

protocol ContractInterface {
  
  var contractAddressHex: String { get }
  func getRecentTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void)
  func refreshLatestTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void)
  
  func getNFT(_ tokenId:UInt) -> NFT
  func getToken(_ tokenId:UInt) -> NFTWithLazyPrice
  func ownerOf(_ tokenId:UInt) -> Promise<EthereumAddress?>
  func getOwnerTokens(address:EthereumAddress,onDone: @escaping () -> Void,_ response: @escaping (NFTWithLazyPrice) -> Void)
  
  func getEventsFetcher(_ tokenId:UInt) -> TokenEventsFetcher?
  
  func indicativeFloor() -> Promise<Double?>
  
  var vaultContract : CollectionVaultContract? { get }
  
  var tradeActions : TokenTradeInterface? { get }
  
  func floorFetcher(_ collection:Collection) -> PagedTokensFetcher?
  
}

func priceIfNotZero(_ price:BigUInt?) -> BigUInt? {
  return price.flatMap { $0 != 0 ? $0 : nil }
}


class CryptoKittiesAuction : ContractInterface {
  func floorFetcher(_ collection:Collection) -> PagedTokensFetcher? { return nil }
  
  var vaultContract: CollectionVaultContract? = nil
  
  var tradeActions: TokenTradeInterface? = nil
  
  func getEventsFetcher(_ tokenId: UInt) -> TokenEventsFetcher? { return nil }
  
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
      print("calling kittyIndexToOwner")
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
    auctionSuccessfulFetcher = LogsFetcher(event:AuctionSuccessful,fromBlock:initFromBlock,address:saleAuctionContract.addressHex,indexedTopics: [],blockDecrements: nil)
  }
  
  private func getOwnerKitties(address:EthereumAddress) -> Promise<KittiesByWallet> {
    
    // https://public.api.cryptokitties.co/v1/kitties?owner_wallet_address=0x007880443b595eb375ab6b6566ad9a52630659ff
    
    return Promise { seal in
      var request = URLRequest(url: URL(string: "https://public.api.cryptokitties.co/v1/kitties?owner_wallet_address=\(address.hex(eip55: false))")!)
      request.httpMethod = "GET"
      request.addValue("Uci2BC2E8vloA_Lmm43gGPXtXhvrSu6AYbac5GmTGy8",forHTTPHeaderField:"x-api-token")
      
      print("calling \(request.url!)")
      URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
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
        blockNumber: log.blockNumber?.quantity,
        indicativePriceWei:.eager(NFTPriceInfo(
                                    price: priceIfNotZero(res["totalPrice"] as? BigUInt),
                                    blockNumber: log.blockNumber?.quantity,
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
          tokenId:UInt(tokenId),
          name:self.name,
          media:.image(self.getMediaImage(tokenId))),
        blockNumber: log.blockNumber?.quantity,
        indicativePriceWei:.eager(NFTPriceInfo(
                                    price: priceIfNotZero(res["totalPrice"] as? BigUInt),
                                    blockNumber: log.blockNumber?.quantity,
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
  
  func getNFT(_ tokenId: UInt) -> NFT {
    NFT(
      address:self.contractAddressHex,
      tokenId:UInt(tokenId),
      name:self.name,
      media:.image(getMediaImage(BigUInt(tokenId))))
  }
  
  
  func getToken(_ tokenId: UInt) -> NFTWithLazyPrice {
    NFTWithLazyPrice(
      nft:getNFT(tokenId),
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
                return NFTPriceStatus.known(NFTPriceInfo(price:priceIfNotZero(event.value),blockNumber:event.blockNumber.quantity,type:event.type))
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
  
  func ownerOf(_ tokenId: UInt) -> Promise<EthereumAddress?> {
    return ethContract.kittyIndexToOwner(BigUInt(tokenId)).map { addressIfNotZero($0) }
  }
  
  func indicativeFloor() -> Promise<Double?> { return Promise.value(nil) }
  
}


class AutoglyphsContract : ContractInterface {
  
  private var drawingCache = try! DiskStorage<BigUInt, Media.Autoglyph>(
    config: DiskConfig(name: "AutoglyphsDrawingsCache",expiry: .never),
    transformer: TransformerFactory.forCodable(ofType: Media.Autoglyph.self))
  
  private var pricesCache : [UInt : ObservablePromise<NFTPriceStatus>] = [:]
  
  private var name = "Autoglyph"
  
  let contractAddressHex = "0xd4e4078ca3495DE5B1d4dB434BEbc5a986197782"
  var tradeActions: TokenTradeInterface? = OpenSeaTradeApi(contract: try!
                                                            EthereumAddress(hex: "0xd4e4078ca3495DE5B1d4dB434BEbc5a986197782", eip55: false))
  
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
  
  func getEventsFetcher(_ tokenId: UInt) -> TokenEventsFetcher? { return ethContract.getEventsFetcher(tokenId) }
  
  
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
      
      response(NFTWithPrice(
        nft:NFT(
          address:self.contractAddressHex,
          tokenId:tokenId,
          name:self.name,
          media:.autoglyph(Media.AutoglyphLazy(tokenId:BigUInt(tokenId), draw: self.draw))),
        blockNumber: log.blockNumber?.quantity,
        indicativePriceWei:.lazy {
          ObservablePromise(
            promise:
              self.ethContract.eventOfTx(transactionHash:log.transactionHash,eventType:.bought)
              .map {
                let price = priceIfNotZero($0?.value);
                return NFTPriceStatus.known(
                  NFTPriceInfo(
                    price:price,
                    blockNumber:log.blockNumber?.quantity,
                    type: price.map { _ in TradeEventType.bought } ?? TradeEventType.transfer))
              }
          )
        }
      ))
    }
  }
  
  func refreshLatestTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
    return ethContract.transfer.updateLatest(onDone:onDone) { index,log in
      let res = try! web3.eth.abi.decodeLog(event:self.ethContract.Transfer,from:log);
      let tokenId = UInt(res["tokenId"] as! BigUInt);
      
      response(NFTWithPrice(
        nft:NFT(
          address:self.contractAddressHex,
          tokenId:tokenId,
          name:self.name,
          media:.autoglyph(Media.AutoglyphLazy(tokenId:BigUInt(tokenId), draw: self.draw))),
        blockNumber: log.blockNumber?.quantity,
        indicativePriceWei:.lazy {
          ObservablePromise(
            promise:
              self.ethContract.eventOfTx(transactionHash:log.transactionHash,eventType:.bought)
              .map {
                let price = priceIfNotZero($0?.value);
                return NFTPriceStatus.known(
                  NFTPriceInfo(
                    price:price,
                    blockNumber:log.blockNumber?.quantity,
                    type: price.map { _ in TradeEventType.bought } ?? TradeEventType.transfer))
              }
          )
        }
      ))
    }
  }
  
  func getNFT(_ tokenId: UInt) -> NFT {
    NFT(
      address:self.contractAddressHex,
      tokenId:tokenId,
      name:self.name,
      media:.autoglyph(Media.AutoglyphLazy(tokenId:BigUInt(tokenId), draw: self.draw)))
  }
  
  func getToken(_ tokenId: UInt) -> NFTWithLazyPrice {
    NFTWithLazyPrice(
      nft:getNFT(tokenId),
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
                return NFTPriceStatus.known(NFTPriceInfo(price:priceIfNotZero(event.value),blockNumber:event.blockNumber.quantity,type:event.type))
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
                return
                  self.ethContract.ethContract.tokenOfOwnerByIndex(address: address,index:index)
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
    return ethContract.ownerOf(tokenId)
  }
  
  func indicativeFloor() -> Promise<Double?> {
    return SushiSwapPool(address:"0x0d9f9c919f1b66a8587a5637b8d1a6a6c5854380").priceInEthRev()
  }
  
  var vaultContract : CollectionVaultContract? = CollectionVaultContract(address:"0xD70240Dd62F4ea9a6A2416e0073D72139489d2AA")
  
  func floorFetcher(_ collection:Collection) -> PagedTokensFetcher? {
    return OpenSeaFloorFetcher.make(collection: collection)
  }
  
}



class BlockFetcherImpl {
  
  private var blocksCache = try! DiskStorage<EthereumQuantityTag, EthereumBlockObject>(
    config: DiskConfig(name: "BlockFetcherCache",expiry: .never),
    transformer: TransformerFactory.forCodable(ofType: EthereumBlockObject.self))
  
  func getBlock(blockNumber:EthereumQuantityTag) -> ObservablePromise<EthereumBlockObject?> {
    return ObservablePromise(
      promise: Promise { seal in
        DispatchQueue.global(qos:.userInteractive).async {
          switch(try? self.blocksCache.object(forKey:blockNumber)) {
          case .some(let p):
            seal.fulfill(p)
          case .none:
            print("getBlockByNumber")
            web3.eth.getBlockByNumber(block:blockNumber, fullTransactionObjects: false)
              .done(on:DispatchQueue.global(qos:.userInteractive)) { seal.fulfill($0) }
              .catch {
                print($0)
                seal.fulfill(nil)
              }
          }
        }
      }
    ) { block in
      block.flatMap { try? self.blocksCache.setObject($0, forKey: blockNumber) }
    }
  }
  
}

var BlocksFetcher = BlockFetcherImpl()


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
        var request = URLRequest(url: URL(string: "https://api.coinbase.com/v2/prices/ETH-\(localCurrencyCode)/spot")!)
        request.httpMethod = "GET"
        
        print("Calling coinbae api for \(localCurrencyCode)")
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
          print("Got response from coinbase")
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
