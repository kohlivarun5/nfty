//
//  CryptoPunksContract.swift
//  NFTY
//
//  Created by Varun Kohli on 4/22/21.
//

import Foundation

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

var web3 = Web3(rpcURL: "https://mainnet.infura.io/v3/b4287cfd0a6b4849bd0ca79e144d3921")

protocol ContractInterface {
  
  var contractAddressHex: String { get }
  func getRecentTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void)
  func refreshLatestTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void)
  func getToken(_ tokenId:UInt) -> Promise<NFTWithLazyPrice>
}

func priceIfNotZero(_ price:BigUInt?) -> BigUInt? {
  return price.flatMap { $0 != 0 ? $0 : nil }
}

class LogsFetcher {
  private var blockDecrements : BigUInt = 10000
  private var toBlock = EthereumQuantityTag.latest
  var mostRecentBlock = EthereumQuantityTag.latest
  
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
  
  func fetch(onDone: @escaping () -> Void,_ response: @escaping (EthereumLogObject) -> Void) {
    
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
      } else {
        print(result)
      }
      onDone()
    }
  }
}

class CryptoPunksContract : ContractInterface {
  
  private var pricesCache : [UInt : Promise<NFTPriceStatus>] = [:]
  
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
  private var punksBoughtLogs : LogsFetcher
  private var initFromBlock = BigUInt(12290614)
  
  init () {
    punksBoughtLogs = LogsFetcher(event:PunkBought,fromBlock:initFromBlock,address:contractAddressHex,indexedTopics: [])
  }
  
  private func imageUrl(_ tokenId:UInt) -> URL? {
    return URL(string:"https://www.larvalabs.com/public/images/cryptopunks/punk\(String(format: "%04d", Int(tokenId))).png")
  }
  
  func getRecentTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
    return punksBoughtLogs.fetch(onDone:onDone) { log in
      let res = try! web3.eth.abi.decodeLog(event:self.PunkBought,from:log);
      response(NFTWithPrice(
        nft:NFT(
          address:self.contractAddressHex,
          tokenId:UInt(res["punkIndex"] as! BigUInt),
          name:self.name,
          media:.image(self.imageUrl(UInt(res["punkIndex"] as! BigUInt))!)),
        indicativePriceWei:NFTPriceInfo(
          price:priceIfNotZero(res["value"] as? BigUInt),
          blockNumber: log.blockNumber?.quantity)
      )
      )
    }
  }
    
  func refreshLatestTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
    return punksBoughtLogs.updateLatest(onDone:onDone) { log in
      let res = try! web3.eth.abi.decodeLog(event:self.PunkBought,from:log);
      response(NFTWithPrice(
        nft:NFT(
          address:self.contractAddressHex,
          tokenId:UInt(res["punkIndex"] as! BigUInt),
          name:self.name,
          media:.image(self.imageUrl(UInt(res["punkIndex"] as! BigUInt))!)),
        indicativePriceWei:NFTPriceInfo(
          price:priceIfNotZero(res["value"] as? BigUInt),
          blockNumber: log.blockNumber?.quantity)
      )
      )
    }
  }
  
  private func getTokenHistory(_ tokenId: UInt,punkBoughtFetcher:LogsFetcher,punkOfferedFetcher:LogsFetcher,retries:UInt) -> Promise<TradeEventStatus> {
    return firstly { () -> Promise<[TradeEvent]> in
      var events : [TradeEvent] = []
      return Promise { seal in
        punkBoughtFetcher.fetch(onDone:{seal.fulfill(events)}) { log in
          let res = try! web3.eth.abi.decodeLog(event:self.PunkBought,from:log);
          log.blockNumber.map { blockNumber in
            events.append(TradeEvent(type: .bought, value: res["value"] as! BigUInt, blockNumber:blockNumber))
          }
        }
      }
    }.then { boughtEvents -> Promise<[TradeEvent]> in
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
    }.compactMap { events in
      events.sorted(by: { $0.blockNumber.quantity > $1.blockNumber.quantity})
    }.then { events -> Promise<TradeEventStatus> in
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
          media:.image(self.imageUrl(tokenId)!)),
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
            
            let p = firstly { () -> Promise<TradeEventStatus> in
              self.getTokenHistory(tokenId,punkBoughtFetcher:punkBoughtFetcher,punkOfferedFetcher:punkOfferedFetcher,retries:10)
            }.map { (event:TradeEventStatus) -> NFTPriceStatus in
              switch(event) {
              case .trade(let event):
                return NFTPriceStatus.known(NFTPriceInfo(price:priceIfNotZero(event.value),blockNumber:event.blockNumber.quantity))
              case .notSeenSince(let since):
                return NFTPriceStatus.notSeenSince(since)
              }
            }
            DispatchQueue.main.async {
              self.pricesCache[tokenId] = p
            }
            return p
          }
        }
      )
    );
  }
  
}

class CryptoKittiesAuction : ContractInterface {
  
  private var pricesCache : [UInt : Promise<NFTPriceStatus>] = [:]
  
  private let AuctionSuccessful: SolidityEvent = SolidityEvent(name: "AuctionSuccessful", anonymous: false, inputs: [
    SolidityEvent.Parameter(name: "tokenId", type: .uint256, indexed: false),
    SolidityEvent.Parameter(name: "totalPrice", type: .uint256, indexed: false),
    SolidityEvent.Parameter(name: "winner", type: .address, indexed: false)
  ])
  
  struct Kitty: Codable {
    var image_url: String
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
  
  private var name = "CryptoKitties"
  let contractAddressHex = "0x06012c8cf97BEaD5deAe237070F9587f8E7A266d"
  private let saleAuctionContract = SaleAuctionContract()
  
  private var auctionSuccessfulFetcher : LogsFetcher
  private let initFromBlock = BigUInt(12290614)
  
  init () {
    auctionSuccessfulFetcher = LogsFetcher(event:AuctionSuccessful,fromBlock:initFromBlock,address:saleAuctionContract.addressHex,indexedTopics: [])
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
          print("JSON Serialization error")
        }
      }).resume()
    }
  }
  
  func getRecentTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
    return auctionSuccessfulFetcher.fetch(onDone:onDone) { log in
      let res = try! web3.eth.abi.decodeLog(event:self.AuctionSuccessful,from:log);
      let tokenId = res["tokenId"] as! BigUInt;
      firstly {
        self.getKitty(tokenId:tokenId)
      }.done { kitty  in
        if (!kitty.image_url.hasSuffix(".svg")) {
          response(NFTWithPrice(
            nft:NFT(
              address:self.contractAddressHex,
              tokenId:UInt(tokenId),
              name:self.name,
              media:.image(URL(string:kitty.image_url)!)),
            indicativePriceWei:NFTPriceInfo(
              price: priceIfNotZero(res["totalPrice"] as? BigUInt),
              blockNumber: log.blockNumber?.quantity)
          ))
        }
      }.catch { print($0) }
    }
  }
  
  func refreshLatestTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
    return auctionSuccessfulFetcher.updateLatest(onDone:onDone) { log in
      let res = try! web3.eth.abi.decodeLog(event:self.AuctionSuccessful,from:log);
      let tokenId = res["tokenId"] as! BigUInt;
      firstly {
        self.getKitty(tokenId:tokenId)
      }.done { kitty  in
        if (!kitty.image_url.hasSuffix(".svg")) {
          response(NFTWithPrice(
            nft:NFT(
              address:self.contractAddressHex,
              tokenId:UInt(tokenId),
              name:self.name,
              media:.image(URL(string:kitty.image_url)!)),
            indicativePriceWei:NFTPriceInfo(
              price: priceIfNotZero(res["totalPrice"] as? BigUInt),
              blockNumber: log.blockNumber?.quantity)
          ))
        }
      }.catch { print($0) }
    }
  }
  
  private func getTokenHistory(_ tokenId: UInt,fetcher:LogsFetcher,retries:UInt) -> Promise<[TradeEvent]> {
    return firstly { () -> Promise<[TradeEvent]> in
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
    }.compactMap { events in
      events.sorted(by: { $0.blockNumber.quantity > $1.blockNumber.quantity})
    }.then { events -> Promise<[TradeEvent]> in
      if (events.count == 0 && retries > 0) {
        return self.getTokenHistory(tokenId,fetcher:fetcher,retries:retries-1)
      } else {
        return Promise.value(events)
      }
    }
  }
  
  func getToken(_ tokenId: UInt) -> Promise<NFTWithLazyPrice> {
    
    firstly {
      self.getKitty(tokenId:BigUInt(tokenId))
    }.compactMap { kitty in
      return NFTWithLazyPrice(
        nft:NFT(
          address:self.contractAddressHex,
          tokenId:UInt(tokenId),
          name:self.name,
          media:.image(URL(string:kitty.image_url)!)),
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
            let p = firstly {
              self.getTokenHistory(tokenId,fetcher:auctionDoneFetcher,retries:10)
            }.map { events in
              return events.first.map { $0 }
            }.map { (event:TradeEvent?) -> NFTPriceStatus in
              NFTPriceStatus.known(NFTPriceInfo(price:priceIfNotZero(event?.value),blockNumber:event?.blockNumber.quantity))
            }
            DispatchQueue.main.async {
              self.pricesCache[tokenId] = p
            }
            return p
          }
        }
      )
    }
  }
}

class AsciiPunksContract : ContractInterface {
  
  private var drawingCache : [BigUInt : Promise<Media.AsciiPunk?>] = [:]
  private var pricesCache : [UInt : Promise<NFTPriceStatus>] = [:]
  
  private let Transfer: SolidityEvent = SolidityEvent(name: "Transfer", anonymous: false, inputs: [
    SolidityEvent.Parameter(name: "from", type: .address, indexed: true),
    SolidityEvent.Parameter(name: "from", type: .address, indexed: true),
    SolidityEvent.Parameter(name: "tokenId", type: .uint256, indexed: true),
  ])
  
  private var name = "AsciiPunks"
  
  let contractAddressHex = "0x5283Fc3a1Aac4DaC6B9581d3Ab65f4EE2f3dE7DC"
  private var transfer : LogsFetcher
  private var initFromBlock = BigUInt(12290614)
  
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
      return firstly {
        method.invoke(tokenId).call()
      }.map { outputs in
        return Media.AsciiPunk(unicode:outputs["uri"] as! String)
      }
    }
  }
  private var ethContract = EthContract()
  
  init () {
    transfer = LogsFetcher(event:Transfer,fromBlock:initFromBlock,address:contractAddressHex,indexedTopics: [])
  }
  
  private func draw(_ tokenId:BigUInt) -> Promise<Media.AsciiPunk?> {
    switch(self.drawingCache[tokenId]) {
    case .some(let p):
      return p
    case .none:
      let p = ethContract.draw(tokenId);
      DispatchQueue.main.async {
        self.drawingCache[tokenId] = p
      }
      return p
    }
  }
  
  private func valueOfTx(tokenId:UInt,transactionHash:EthereumData?,eventType:TradeEventType) -> Promise<TradeEvent?> {
    
    firstly { () -> Promise<EthereumTransactionObject?> in
      switch(transactionHash) {
      case .none:
        return Promise<EthereumTransactionObject?>.value(nil)
      case .some(let blockHash):
        return web3.eth.getTransactionByHash(blockHash:blockHash)
      }
    }.map { (txData:EthereumTransactionObject?) in
      switch(txData) {
      case .none: return nil
      case .some(let tx):
        switch(tx.value.quantity,tx.blockNumber) {
        case (_,.none): return nil
        case (let value,.some(let blockNumber)):
          return TradeEvent(type:eventType,value:value,blockNumber: blockNumber)
        }
      }
    }
  }
  
  func getRecentTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
    return transfer.fetch(onDone:onDone) { log in
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
      
      firstly {
        self.valueOfTx(tokenId:tokenId,transactionHash:log.transactionHash,eventType:.bought)
      }.done(on:.main) {
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

      firstly {
        self.valueOfTx(tokenId:tokenId,transactionHash:log.transactionHash,eventType:.bought)
      }.done(on:.main) {
        onPrice($0?.value)
      }.catch { error in
        print(error);
        onPrice(nil)
      }
    }
  }
  
  private func getTokenHistory(_ tokenId: UInt,fetcher:LogsFetcher,retries:UInt) -> Promise<[TradeEvent]> {
    return firstly { () -> Promise<[TradeEvent]> in
      var events : [Promise<TradeEvent?>] = []
      return Promise { seal in
        fetcher.fetch(onDone:{
          firstly {
            when(fulfilled:events)
          }.done { events in
            seal.fulfill(events.filter { $0 != nil }.map { $0! })
          }
        }) { log in
          events.append(
            firstly {
              self.valueOfTx(tokenId:tokenId,transactionHash:log.transactionHash,eventType:.bought)
            })
        }
      }
    }.compactMap { events in
      events.sorted(by: { $0.blockNumber.quantity > $1.blockNumber.quantity})
    }.then { events -> Promise<[TradeEvent]> in
      if (events.count == 0 && retries > 0) {
        return self.getTokenHistory(tokenId,fetcher:fetcher,retries:retries-1)
      } else {
        return Promise.value(events)
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
                     
            let p = firstly { () -> Promise<[TradeEvent]> in
              self.getTokenHistory(tokenId,fetcher:transerFetcher,retries:10)
            }.map { events in
              return events.first
            }.map { (event:TradeEvent?) -> NFTPriceStatus in
              return NFTPriceStatus.known(NFTPriceInfo(price:priceIfNotZero(event?.value),blockNumber:event?.blockNumber.quantity))
            }
            DispatchQueue.main.async { self.pricesCache[tokenId] = p }
            return p
          }
        }
      )
    );
  }
  
}

class BlockFetcherImpl {
  private var blocksCache : [EthereumQuantityTag:Promise<EthereumBlockObject?>] = [:]
  
  func getBlock(blockNumber:EthereumQuantityTag) -> Promise<EthereumBlockObject?> {
    switch(self.blocksCache[blockNumber]) {
    case .some(let p):
      return p
    case .none:
      let p = firstly {
        web3.eth.getBlockByNumber(block:blockNumber, fullTransactionObjects: false)
      }
      DispatchQueue.main.async {
        self.blocksCache[blockNumber] = p
      }
      return p
    }
  }
  
}

var BlocksFetcher = BlockFetcherImpl()
