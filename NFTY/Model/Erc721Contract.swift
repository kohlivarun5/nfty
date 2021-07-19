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
    
    /*
     func name() -> Promise<String> {
     let outputs = [SolidityFunctionParameter(name: "name", type: .string)]
     let method = SolidityConstantFunction(name: "name", outputs: outputs, handler: self)
     return method.invoke().call()
     .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs in
     return outputs["name"] as! String
     }
     }
     */
    
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
    
    
    func tokenURI(tokenId: BigUInt) -> Promise<String> {
      let inputs = [SolidityFunctionParameter(name: "tokenId", type: .uint256)]
      let outputs = [SolidityFunctionParameter(name: "tokenURI", type: .string)]
      let method = SolidityConstantFunction(name: "tokenURI", inputs: inputs, outputs: outputs, handler: self)
      return method.invoke(tokenId).call()
        .map(on:DispatchQueue.global(qos:.userInteractive)) { outputs in
          return outputs["tokenURI"] as! String
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
  
  /*
   struct ERC721MetaData : Decodable {
   let image : String
   }
   
   private func getUriData(_ tokenURI:String) -> Promise<ERC721MetaData?> {
   print(tokenURI)
   return Promise { seal in
   var request = URLRequest(url: URL(string:tokenURI)!)
   request.httpMethod = "GET"
   
   URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
   do {
   let jsonDecoder = JSONDecoder()
   print("json=\(data.map { String(decoding: $0, as: UTF8.self) } ?? "")")
   let metadata = try jsonDecoder.decode(ERC721MetaData.self, from: data!)
   seal.fulfill(metadata)
   } catch {
   print("JSON Serialization error:\(error), json=\(data.map { String(decoding: $0, as: UTF8.self) } ?? "")")
   seal.fulfill(nil)
   }
   }).resume()
   }
   }
   
   private func getMediaImage(_ tokenId:BigUInt) -> MediaImageLazy {
   print(tokenId)
   return MediaImageLazy(get: {
   switch (self.imagesCache[tokenId]) {
   case .some(let p):
   return p
   case .none:
   let p =
   self.ethContract.tokenURI(tokenId: tokenId)
   .then(on:DispatchQueue.global(qos:.userInteractive)) { self.getUriData($0) }
   .map(on:DispatchQueue.global(qos:.userInteractive)) { $0.flatMap { URL(string:$0.image) }! }
   let observable = ObservablePromise(promise: p)
   DispatchQueue.main.async {
   self.imagesCache[tokenId] = observable
   }
   return observable
   }
   })
   }
   
   */
  
  var ethContract : EthContract
  // private var name : Promise<String>
  
  init (address:String) {
    self.contractAddressHex = address
    ethContract = EthContract(address)
    initFromBlock = (UserDefaults.standard.string(forKey: "\(address).initFromBlock").flatMap { BigUInt($0)}) ?? INIT_BLOCK
    transfer = LogsFetcher(event:Transfer,fromBlock:initFromBlock,address:contractAddressHex,indexedTopics: [],blockDecrements: nil)
    // name = ethContract.name()
  }
  
  func eventOfTx(transactionHash:EthereumData?,eventType:TradeEventType) -> Promise<TradeEvent?> {
    
    txFetcher.eventOfTx(transactionHash: transactionHash)
      .map(on:DispatchQueue.global(qos:.userInteractive)) { (txData:TxFetcher.TxInfo?) in
        switch(txData) {
        case .none: return nil
        case .some(let tx):
          return TradeEvent(type:eventType,value:tx.value,blockNumber:tx.blockNumber)
        }
      }
  }
  
  /*
   func getRecentTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
   name.done(on:DispatchQueue.global(qos:.userInteractive)) { name in
   return self.transfer.fetch(onDone:onDone) { log in
   let res = try! web3.eth.abi.decodeLog(event:self.Transfer,from:log);
   let tokenId = UInt(res["tokenId"] as! BigUInt);
   
   let onPrice = { (indicativePriceWei:BigUInt?) in
   print(tokenId)
   response(NFTWithPrice(
   nft:NFT(
   address:self.contractAddressHex,
   tokenId:tokenId,
   name:name,
   media:.image(self.getMediaImage(BigUInt(tokenId)))),
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
   }.catch {
   print($0);
   onDone()
   }
   }
   
   func refreshLatestTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
   
   name.done(on:DispatchQueue.global(qos:.userInteractive)) { name in
   
   return self.transfer.updateLatest(onDone:onDone) { log in
   let res = try! web3.eth.abi.decodeLog(event:self.Transfer,from:log);
   let tokenId = UInt(res["tokenId"] as! BigUInt);
   
   let onPrice = { (indicativePriceWei:BigUInt?) in
   response(NFTWithPrice(
   nft:NFT(
   address:self.contractAddressHex,
   tokenId:tokenId,
   name:name,
   media:.image(self.getMediaImage(BigUInt(tokenId)))),
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
   }.catch {
   print($0);
   onDone()
   }
   }
   */
  
  
  func getTokenHistory(_ tokenId: UInt,fetcher:LogsFetcher,retries:UInt) -> Promise<TradeEventStatus> {
    var events : [Promise<TradeEvent?>] = []
    return Promise { seal in
      fetcher.fetch(onDone:{
        when(fulfilled:events)
          .done(on:DispatchQueue.global(qos:.userInteractive)) { events in
            seal.fulfill(events.filter { $0 != nil }.map { $0! })
          }.catch { print ($0) }
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
  
  /*
   
   func getToken(_ tokenId: UInt) -> Promise<NFTWithLazyPrice> {
   name.map(on:DispatchQueue.global(qos:.userInteractive)) { name in
   NFTWithLazyPrice(
   nft:NFT(
   address:self.contractAddressHex,
   tokenId:tokenId,
   name:name,
   media:.image(self.getMediaImage(BigUInt(tokenId)))),
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
   indexedTopics: [nil,nil,tokenIdTopic],
   blockDecrements: 10000)
   
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
   }
   }
   
   func getOwnerTokens(
   address: EthereumAddress,
   onDone: @escaping () -> Void,
   _ response: @escaping (NFTWithLazyPrice) -> Void) {
   
   name.done(on:DispatchQueue.global(qos:.userInteractive)) { name in
   
   self.ethContract.balanceOf(address:address)
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
   }.catch { print ($0) }
   }.catch {
   print($0);
   onDone()
   }
   }
   
   */
  
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
    init(transferFetcher:LogsFetcher) {
      self.transferFetcher = transferFetcher
    }
    
    func getEvents(onDone: @escaping () -> Void,_ response: @escaping (TradeEvent) -> Void) {
      var reachedMint = false
      
      return transferFetcher.fetchAllLogs(onDone: {
        if (reachedMint) { onDone() }
      }) { log in
        let res = try! web3.eth.abi.decodeLog(event:self.Transfer,from:log)
        let from = res["from"] as! EthereumAddress
        
        var type : TradeEventType = .bought
        
        if (from == EthereumAddress(hexString: "0x0000000000000000000000000000000000000000")) {
          reachedMint = true
          type = .minted
        }
          
        txFetcher.eventOfTx(transactionHash: log.transactionHash)
          .map(on:DispatchQueue.global(qos:.userInteractive)) { (txData:TxFetcher.TxInfo?) in
            switch(txData) {
            case .none:
              return TradeEvent(type:.transfer,value:BigUInt(0),blockNumber:log.blockNumber!)
            case .some(let tx):
              return TradeEvent(type:type,value:tx.value,blockNumber:tx.blockNumber)
            }
          }.done { response($0) }
          .catch { print($0) }
      }
    }
  }
  
  func getEventsFetcher(_ tokenId: UInt) -> TokenEventsFetcher? {
    
    let tokenIdTopic = try! ABI.encodeParameter(SolidityWrappedValue.uint(BigUInt(tokenId)))
    let transerFetcher = LogsFetcher(
      event:self.Transfer,
      fromBlock:self.initFromBlock,
      address:self.contractAddressHex,
      indexedTopics: [nil,nil,tokenIdTopic],
      blockDecrements: 10000)
    
    return EventsFetcher(transferFetcher:transerFetcher)
  }
}


class IpfsCollectionContract : ContractInterface {
  
  class IpfsImageEthContract : Erc721Contract {
    
    struct TokenUriData : Codable {
      let image : String
    }
    
    func image(_ tokenId:BigUInt) -> Promise<Media.IpfsImage?> {
      return ethContract.tokenURI(tokenId:tokenId)
        .then(on: DispatchQueue.global(qos:.userInteractive)) { (uri:String) -> Promise<TokenUriData> in
          
          return Promise { seal in
            
            var request = URLRequest(
              url:URL(string: uri.replacingOccurrences(of: "ipfs://", with: "https://ipfs.infura.io:5001/api/v0/cat?arg="))!)
            request.httpMethod = "GET"
            
            
            URLSession.shared.dataTask(with: request,completionHandler:{ data, response, error -> Void in
              // print(data,response,error)
              do {
                switch(data) {
                case .some(let data):
                  if (data.isEmpty) {
                    // print(data,response,error)
                    seal.reject(NSError(domain:"", code:404, userInfo:nil))
                  } else {
                    seal.fulfill(try JSONDecoder().decode(TokenUriData.self, from: data))
                  }
                case .none:
                  // print(data,response,error)
                  seal.reject(error ?? NSError(domain:"", code:404, userInfo:nil))
                }
              } catch {
                // print(data,response,error)
                seal.reject(error)
              }
            }).resume()
          }
          
        }.then(on: DispatchQueue.global(qos:.userInteractive)) { (uriData:TokenUriData) -> Promise<Media.IpfsImage?> in
          
          return Promise { seal in
            
            var request = URLRequest(
              url:URL(string:uriData.image.replacingOccurrences(of: "ipfs://", with: "https://ipfs.infura.io:5001/api/v0/cat?arg="))!)
            request.httpMethod = "GET"
            
            URLSession.shared.dataTask(with: request,completionHandler:{ data, response, error -> Void in
              // print(data,response,error)
              seal.fulfill(data.map { Media.IpfsImage(data:$0) })
            }).resume()
          }
        }
    }
  }
  
  private var imageCache : DiskStorage<BigUInt, Media.IpfsImage>
  private var pricesCache : [UInt : ObservablePromise<NFTPriceStatus>] = [:]
  
  let name : String
  let contractAddressHex : String
  var ethContract : IpfsImageEthContract
  
  init(name:String,address:String) {
    self.imageCache = try! DiskStorage<BigUInt, Media.IpfsImage>(
      config: DiskConfig(name: "\(name).ImageCache",expiry: .never),
      transformer: TransformerFactory.forCodable(ofType: Media.IpfsImage.self))
    self.name = name
    self.contractAddressHex = address
    self.ethContract = IpfsImageEthContract(address:address)
  }
  
  func getEventsFetcher(_ tokenId: UInt) -> TokenEventsFetcher? {
    return ethContract.getEventsFetcher(tokenId)
  }
  
  private func download(_ tokenId:BigUInt) -> ObservablePromise<Media.IpfsImage?> {
    switch(try? imageCache.object(forKey:tokenId)) {
    case .some(let p):
      return ObservablePromise(resolved: p)
    case .none:
      
      let p = ethContract.image(tokenId);
      let observable = ObservablePromise(promise: p) { image in
        image.flatMap {
          try? self.imageCache.setObject($0, forKey: tokenId)
        }
      }
      return observable
    }
  }
  
  func getRecentTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
    return ethContract.transfer.fetch(onDone:onDone) { log in
      
      let res = try! web3.eth.abi.decodeLog(event:self.ethContract.Transfer,from:log);
      let tokenId = UInt(res["tokenId"] as! BigUInt);
      
      response(NFTWithPrice(
        nft:NFT(
          address:self.contractAddressHex,
          tokenId:tokenId,
          name:self.name,
          media:.ipfsImage(Media.IpfsImageLazy(tokenId:BigUInt(tokenId), download: self.download))),
        blockNumber: log.blockNumber?.quantity,
        indicativePriceWei:.lazy(
          ObservablePromise(
            promise:
              self.ethContract.eventOfTx(transactionHash:log.transactionHash,eventType:.bought)
              .map {
                .known(NFTPriceInfo(
                        price:priceIfNotZero($0?.value),
                        blockNumber:log.blockNumber?.quantity))
              }
          ))
      ))
    }
  }
  
  func refreshLatestTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
    return ethContract.transfer.updateLatest(onDone:onDone) { log in
      let res = try! web3.eth.abi.decodeLog(event:self.ethContract.Transfer,from:log);
      let tokenId = UInt(res["tokenId"] as! BigUInt);
      
      response(NFTWithPrice(
        nft:NFT(
          address:self.contractAddressHex,
          tokenId:tokenId,
          name:self.name,
          media:.ipfsImage(Media.IpfsImageLazy(tokenId:BigUInt(tokenId), download: self.download))),
        blockNumber: log.blockNumber?.quantity,
        indicativePriceWei:.lazy(
          ObservablePromise(
            promise:
              self.ethContract.eventOfTx(transactionHash:log.transactionHash,eventType:.bought)
              .map {
                .known(NFTPriceInfo(
                        price:priceIfNotZero($0?.value),
                        blockNumber:log.blockNumber?.quantity))
              }
          ))
      ))
    }
  }
  
  func getToken(_ tokenId: UInt) -> Promise<NFTWithLazyPrice> {
    
    Promise.value(
      NFTWithLazyPrice(
        nft:NFT(
          address:self.contractAddressHex,
          tokenId:tokenId,
          name:self.name,
          media:.ipfsImage(Media.IpfsImageLazy(tokenId:BigUInt(tokenId), download: self.download))),
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
              indexedTopics: [nil,nil,tokenIdTopic],
              blockDecrements: 10000)
            
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
