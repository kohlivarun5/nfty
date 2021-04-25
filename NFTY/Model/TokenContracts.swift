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
  func getRecentTrades(onDone: @escaping () -> Void,_ response: @escaping (NFT) -> Void)
  func getToken(_ tokenId:UInt) -> Promise<NFT>
}

class LogsFetcher {
  private var blockDecrements : BigUInt = 10000
  private var toBlock = EthereumQuantityTag.latest
  
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
        }
      }
      onDone()
    }
  }
}

class CryptoPunksContract : ContractInterface {
  
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
  
  func getRecentTrades(onDone: @escaping () -> Void,_ response: @escaping (NFT) -> Void) {
    // print("Called getRecentTrades");
    return punksBoughtLogs.fetch(onDone:onDone) { log in
      let res = try! web3.eth.abi.decodeLog(event:self.PunkBought,from:log);
      response(NFT(
        address:self.contractAddressHex,
        tokenId:UInt(res["punkIndex"] as! BigUInt),
        name:self.name,
        url:self.imageUrl(UInt(res["punkIndex"] as! BigUInt))!,
        indicativePriceWei:res["value"] as? BigUInt
      ))
    }
  }
  
  private func getTokenHistory(_ tokenId: UInt,punkBoughtFetcher:LogsFetcher,punkOfferedFetcher:LogsFetcher,retries:UInt) -> Promise<[TradeEvent]> {
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
      events
        .sorted(by: { $0.blockNumber.quantity > $1.blockNumber.quantity})
        .filter({ $0.value != BigUInt(0)})
    }.then { events -> Promise<[TradeEvent]> in
      if (events.count == 0 && retries > 0) {
        return self.getTokenHistory(tokenId,punkBoughtFetcher:punkBoughtFetcher,punkOfferedFetcher:punkOfferedFetcher,retries:retries-1)
      } else {
        return Promise.value(events)
      }
    }
  }
  
  func getToken(_ tokenId: UInt) -> Promise<NFT> {
    let tokenIdTopic = try! ABI.encodeParameter(SolidityWrappedValue.uint(BigUInt(tokenId)))
    let punkBoughtFetcher = LogsFetcher(
      event:PunkBought,
      fromBlock:initFromBlock,
      address:contractAddressHex,
      indexedTopics: [tokenIdTopic])
    
    let punkOfferedFetcher = LogsFetcher(
      event:self.PunkOffered,
      fromBlock:self.initFromBlock,
      address:self.contractAddressHex,
      indexedTopics: [tokenIdTopic])
    
    return firstly { () -> Promise<[TradeEvent]> in
      self.getTokenHistory(tokenId,punkBoughtFetcher:punkBoughtFetcher,punkOfferedFetcher:punkOfferedFetcher,retries:10)
    }.compactMap { events in
      NFT(
        address:self.contractAddressHex,
        tokenId:tokenId,
        name:self.name,
        url:self.imageUrl(tokenId)!,
        indicativePriceWei:events.first.map { $0.value }
      )
    }
  }
  
}

class CryptoKittiesAuction : ContractInterface {
  
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
    
    /* func getCurrentPrice(tokenId: BigUInt) -> Promise<BigUInt?> {
      let inputs = [SolidityFunctionParameter(name: "_tokenId", type: .uint256)]
      let outputs = [SolidityFunctionParameter(name: "price", type: .uint256)]
      let method = SolidityConstantFunction(name: "getCurrentPrice", inputs: inputs, outputs: outputs, handler: self)
      print(method);
      return firstly {
        method.invoke(tokenId).call()
      }.map { outputs in
        print(outputs);
        return outputs["price"] as? BigUInt
      }
    } */
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
  
  func getRecentTrades(onDone: @escaping () -> Void,_ response: @escaping (NFT) -> Void) {
    return auctionSuccessfulFetcher.fetch(onDone:onDone) { log in
      let res = try! web3.eth.abi.decodeLog(event:self.AuctionSuccessful,from:log);
      let tokenId = res["tokenId"] as! BigUInt;
      firstly {
        self.getKitty(tokenId:tokenId)
      }.done { kitty  in
        if (!kitty.image_url.hasSuffix(".svg")) {
          response(NFT(
            address:self.contractAddressHex,
            tokenId:UInt(tokenId),
            name:self.name,
            url:URL(string:kitty.image_url)!,
            indicativePriceWei:res["totalPrice"] as? BigUInt
          ))
        }
      }
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
      events
        .sorted(by: { $0.blockNumber.quantity > $1.blockNumber.quantity})
        .filter({ $0.value != BigUInt(0)})
    }.then { events -> Promise<[TradeEvent]> in
      if (events.count == 0 && retries > 0) {
        return self.getTokenHistory(tokenId,fetcher:fetcher,retries:retries-1)
      } else {
        return Promise.value(events)
      }
    }
  }
   
  func getToken(_ tokenId: UInt) -> Promise<NFT> {
    let auctionDoneFetcher = LogsFetcher(event:AuctionSuccessful,fromBlock:initFromBlock,address:saleAuctionContract.addressHex,indexedTopics: [])
    return firstly {
      when(fulfilled:self.getKitty(tokenId:BigUInt(tokenId)),self.getTokenHistory(tokenId,fetcher:auctionDoneFetcher,retries:10))
    }.compactMap { kitty,events in
      return NFT(
        address:self.contractAddressHex,
        tokenId:UInt(tokenId),
        name:self.name,
        url:URL(string:kitty.image_url)!,
        indicativePriceWei:events.first.map { $0.value }
      )
    }
  }
}
