//
//  IpfsCollectionContract.swift
//  NFTY
//
//  Created by Varun Kohli on 8/8/21.
//

import Foundation
import Web3
import Web3PromiseKit
import Web3ContractABI
import Cache
import UIKit
import CloudKit


class IpfsCollectionContract : ContractInterface {
  
  class IpfsImageEthContract : Erc721Contract {
    
    struct TokenUriData : Codable {
      let image : String?
      let image_url : String?
    }
    
    static let UrlSession = UrlTaskThrottle(
      queue:DispatchQueue(label: "IpfsImageEthContract.serialQueue",qos:.userInitiated),
      deadline:DispatchTimeInterval.milliseconds(50),
      timeoutIntervalForRequest:5.0,
      timeoutIntervalForResource: 10.0)
    
    private static let base64JsonPrefix = "data:application/json;base64,"
    private static let utf8JsonPrefix = "data:application/json;utf8,"
    
    func image_Alchemy(_ tokenId:BigUInt) -> Promise<Data?> {
      return AlchemyApi.GetNFTMetaData.get(contractAddress: ethContract.address!, tokenId: tokenId, tokenType: .ERC721)
        .then { result -> Promise<Data?> in
          
          guard let media = result.media.first else { return Promise.value(nil) }
          
          return Promise { seal in
            let uri = media.gateway // ?? media.raw
            guard let url = URL(string:uri) else { return seal.reject(NSError(domain:"", code:404, userInfo:nil)) }
            
            var request = URLRequest(url:url)
            request.httpMethod = url.host.map { $0 == "ipfs.infura.io" ? "POST" : "GET"} ?? "GET"
            
            IpfsImageEthContract.UrlSession.enqueue(
              with: request,
              completionHandler:{ data, response, error -> Void in
                if let error = error { return seal.reject(error) }
                // print(data,response,error)
                seal.fulfill(data)
              }
            )
          }
        }
    }
    
    func image_raw(_ tokenId:BigUInt) -> Promise<Data?> {
      
      return ethContract.tokenURI(tokenId:tokenId)
        .then(on: DispatchQueue.global(qos:.userInteractive)) { (uri:String) -> Promise<TokenUriData> in
          
          if (uri.hasPrefix(IpfsImageEthContract.base64JsonPrefix)) {
            do {
              var index = uri.firstIndex(of: ",")!
              uri.formIndex(after: &index)
              let str : String = String(uri.suffix(from:index))
              let data = Data(base64Encoded: str)!
              return Promise.value(try JSONDecoder().decode(TokenUriData.self, from: data))
            } catch {
              return Promise(error: error)
            }
          }  else if(uri.hasPrefix(IpfsImageEthContract.utf8JsonPrefix)){
            do {
              var index = uri.firstIndex(of: ",")!
              uri.formIndex(after: &index)
              let str : String = String(uri.suffix(from:index))
              let data = str.data(using:.utf8)!
              return Promise.value(try JSONDecoder().decode(TokenUriData.self, from: data))
            } catch {
              return Promise(error: error)
            }
          }
          
          return Promise { seal in
            
            
            
            switch(URL(string: ipfsUrl(uri))) {
            case .none:
              seal.reject(NSError(domain:"", code:404, userInfo:nil))
            case .some(let url):
              var request = URLRequest(url:url)
              request.httpMethod = url.host.map { $0 == "ipfs.infura.io" ? "POST" : "GET"} ?? "GET"
              
              IpfsImageEthContract.UrlSession.enqueue(
                with: request,
                completionHandler:{ data, response, error -> Void in
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
                    print("Error parsing image\(data.map { String(decoding:$0,as:UTF8.self) } ?? "EmptyData")",error)
                    seal.reject(error)
                  }
                }
              )
            }
          }
          
        }.then(on: DispatchQueue.global(qos:.userInitiated)) { (uriData:TokenUriData) -> Promise<Data?> in
          
          return Promise { seal in
            let uri = (uriData.image == nil ? uriData.image_url : uriData.image)
            
            switch(
              uri
                .map(ipfsUrl)
                .flatMap { URL(string:$0) }
            ) {
            case .none:
              seal.reject(NSError(domain:"", code:404, userInfo:nil))
            case .some(let url):
              var request = URLRequest(url:url)
              request.httpMethod = url.host.map { $0 == "ipfs.infura.io" ? "POST" : "GET"} ?? "GET"
              
              IpfsImageEthContract.UrlSession.enqueue(
                with: request,
                completionHandler:{ data, response, error -> Void in
                  if let error = error { return seal.reject(error) }
                  // print(data,response,error)
                  seal.fulfill(data)
                }
              )
            }
          }
        }
    }
    
    
    func image(_ tokenId:BigUInt) -> Promise<Data?> {
      self.image_Alchemy(tokenId)
        .recover { error -> Promise<Data?> in
          print("Alchemy Image fetch failed with \(error)")
          return Promise.value(nil)
        }.then { (data:Data?) -> Promise<Data?> in
          switch (data) {
          case .some(let data):
            return Promise.value(data)
          case .none:
            return self.image_raw(tokenId)
          }
        }
    }
  }
  
  private var imageCache : CKImageCacheCore
  private var pricesCache : [UInt : ObservablePromise<NFTPriceStatus>] = [:]
  
  let name : String
  let contractAddressHex : String
  var ethContract : IpfsImageEthContract
  
  var tradeActions: TokenTradeInterface?
  
  enum IndicativePrice {
    case swapPoolContract(pool:String,vault:String)
    case swapPoolContractReversed(pool:String,vault:String)
    case openSea
  }
  
  var indicativePriceSource : IndicativePrice
  
  init(name:String,address:String,indicativePriceSource:IndicativePrice) {
    self.name = name
    self.contractAddressHex = address
    self.ethContract = IpfsImageEthContract(address:address)
    self.imageCache = CKImageCacheCore(
      database: CKPublicDataManager.defaultContainer.publicCloudDatabase,
      bucket: "collections/\(contractAddressHex.lowercased())/images",
      fallback:self.ethContract.image)
    self.tradeActions = OpenSeaTradeApi(contract: try! EthereumAddress(hex: contractAddressHex, eip55: false))
    self.indicativePriceSource = indicativePriceSource
  }
  
  func getEventsFetcher(_ tokenId: BigUInt) -> TokenEventsFetcher? {
    return ethContract.getEventsFetcher(tokenId)
  }
  
  private func download(_ tokenId:BigUInt) -> ObservablePromise<Media.IpfsImage?> {
    return imageCache.image(tokenId)
  }
  
  func getRecentTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
    return ethContract.transfer.fetch(onDone:onDone) { log in
      
      let res = try! web3.eth.abi.decodeLog(event:self.ethContract.Transfer,from:log);
      let tokenId = res["tokenId"] as! BigUInt
      let isMint = res["from"] as! EthereumAddress == EthereumAddress(hexString: "0x0000000000000000000000000000000000000000")!
      
      response(NFTWithPrice(
        nft:NFT(
          address:self.contractAddressHex,
          tokenId:tokenId,
          name:self.name,
          media:.ipfsImage(Media.IpfsImageLazy(tokenId:tokenId, download: self.download))),
        blockNumber: log.blockNumber.map { .ethereum($0) },
        indicativePrice:.lazy {
          ObservablePromise(
            promise:
              self.ethContract.eventOfTx(transactionHash:log.transactionHash,eventType:isMint ? .minted : .bought)
              .map {
                let price = priceIfNotZero($0?.value);
                return NFTPriceStatus.known(
                  NFTPriceInfo(
                    wei:price,
                    blockNumber: log.blockNumber.map { .ethereum($0) },
                    type: isMint ? .minted : price.map { _ in TradeEventType.bought } ?? TradeEventType.transfer))
              }
          )
        }
      ))
    }
  }
  
  func refreshLatestTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
    return ethContract.transfer.updateLatest(onDone:onDone) { index,log in
      let res = try! web3.eth.abi.decodeLog(event:self.ethContract.Transfer,from:log);
      let tokenId = res["tokenId"] as! BigUInt
      let isMint = res["from"] as! EthereumAddress == EthereumAddress(hexString: "0x0000000000000000000000000000000000000000")!
      
      response(NFTWithPrice(
        nft:NFT(
          address:self.contractAddressHex,
          tokenId:tokenId,
          name:self.name,
          media:.ipfsImage(Media.IpfsImageLazy(tokenId:tokenId, download: self.download))),
        blockNumber: log.blockNumber.map { .ethereum($0) },
        indicativePrice:.lazy {
          ObservablePromise(
            promise:
              self.ethContract.eventOfTx(transactionHash:log.transactionHash,eventType:isMint ? .minted : .bought)
              .map {
                let price = priceIfNotZero($0?.value);
                return NFTPriceStatus.known(
                  NFTPriceInfo(
                    wei:price,
                    blockNumber: log.blockNumber.map { .ethereum($0) },
                    type: isMint ? .minted : price.map { _ in TradeEventType.bought } ?? TradeEventType.transfer))
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
      media:.ipfsImage(Media.IpfsImageLazy(tokenId:tokenId, download: self.download)))
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
    return AlchemyApi.GetFloor.indicativeFloor(self.contractAddressHex)
      .recover { error -> Promise<PriceUnit?> in
        print(error)
        switch(self.indicativePriceSource) {
        case .openSea:
          return Promise.value(nil)
        case .swapPoolContract(let address,_):
          return SushiSwapPool(address:address).priceInEth()
        case .swapPoolContractReversed(let address,_):
          return SushiSwapPool(address:address).priceInEthRev()
        }
      }
  }
  
  lazy var vaultContract: CollectionVaultContract? = {
    switch(self.indicativePriceSource) {
    case .openSea:
      return nil
    case .swapPoolContract(_,let address),.swapPoolContractReversed(_,let address):
      return CollectionVaultContract(address:address)
    }
  }()
  
  
  func floorFetcher(_ collection:Collection) -> PagedTokensFetcher? {
    return OpenSeaFloorFetcher.make(collection:collection)
  }
  
}
