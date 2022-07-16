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
import CloudKit

#if os(macOS)
import AppKit
#endif


class IpfsCollectionContract : ContractInterface {
  
  class IpfsImageEthContract : Erc721Contract {
    
    struct TokenUriData : Codable {
      let image : String?
      let image_url : String?
      let image_data : String?
    }
    
    static let UrlSession = UrlTaskThrottle(
      queue:DispatchQueue(label: "IpfsImageEthContract.serialQueue",qos:.userInitiated),
      deadline:DispatchTimeInterval.milliseconds(50),
      timeoutIntervalForRequest:3.0,
      timeoutIntervalForResource: 10.0)
    
    private static let base64JsonPrefix = "data:application/json;base64,"
    private static let utf8JsonPrefix = "data:application/json;utf8,"
    
    private static let base64SvgXmlPrefix = "data:image/svg+xml;base64,"
    
    func image_Alchemy(_ tokenId:BigUInt) -> Promise<Media.ImageData?> {
      return AlchemyApi.GetNFTMetaData.get(contractAddress: ethContract.address!, tokenId: tokenId, tokenType: .ERC721)
        .then { result -> Promise<Media.ImageData?> in
          
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
                guard let data = data else { return seal.reject(NSError(domain:"Failed to get data for url=\(url)", code:404, userInfo:nil)) }
                // print(data,response,error)
                seal.fulfill(Media.ImageData.image(data))
              }
            )
          }
        }
    }
    
    func image_raw(_ tokenId:BigUInt) -> Promise<Media.ImageData?> {
      
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
          
        }.then(on: DispatchQueue.global(qos:.userInitiated)) { (uriData:TokenUriData) -> Promise<Media.ImageData?> in
          
          return Promise { seal in
            let uri = uriData.image ?? uriData.image_url ?? uriData.image_data
            
            guard let uri = uri else { return seal.reject(NSError(domain:"", code:404, userInfo:nil)) }
            
            guard !uri.hasPrefix(IpfsImageEthContract.base64SvgXmlPrefix) else {
              var index = uri.firstIndex(of: ",")!
              uri.formIndex(after: &index)
              let str : String = String(uri.suffix(from:index))
              let data =  Data(base64Encoded: str)!
              return seal.fulfill(Media.ImageData.svg(data))
            }
            
            switch(URL(string:ipfsUrl(uri))) {
            case .none:
              seal.reject(NSError(domain:"", code:404, userInfo:nil))
            case .some(let url):
              var request = URLRequest(url:url)
              request.httpMethod = url.host.map { $0 == "ipfs.infura.io" ? "POST" : "GET"} ?? "GET"
              
              IpfsImageEthContract.UrlSession.enqueue(
                with: request,
                completionHandler:{ data, response, error -> Void in
                  if let error = error { return seal.reject(error) }
                  guard let data = data else { return seal.reject(NSError(domain:"Failed to get data for url=\(url)", code:404, userInfo:nil)) }
                  // print(data,response,error)
                  seal.fulfill(Media.ImageData.image(data))
                }
              )
            }
          }
        }
    }
    
    
    func image(_ tokenId:BigUInt) -> Promise<Media.ImageData?> {
      self.image_Alchemy(tokenId)
        .recover { error -> Promise<Media.ImageData?> in
          print("Alchemy Image fetch failed with \(error)")
          return Promise.value(nil)
        }.then { (data:Media.ImageData?) -> Promise<Media.ImageData?> in
          switch (data) {
          case .some(let data):
            return Promise.value(data)
          case .none:
            return self.image_raw(tokenId)
          }
        }
    }
  }
  
#if !os(macOS)
  private var imageCache : CKImageCacheCore
#endif
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
    
#if os(macOS)
    self.tradeActions = nil
#else
    self.imageCache = CKImageCacheCore(
      database: CKPublicDataManager.defaultContainer.publicCloudDatabase,
      bucket: "collections/\(contractAddressHex.lowercased())/images",
      collectionAddress: contractAddressHex,
      fallback:self.ethContract.image)
    self.tradeActions = OpenSeaTradeApi(contract: try! EthereumAddress(hex: contractAddressHex, eip55: false))
#endif
    self.indicativePriceSource = indicativePriceSource
  }
  
  func getEventsFetcher(_ tokenId: BigUInt) -> TokenEventsFetcher? {
    return ethContract.getEventsFetcher(tokenId)
  }
  
  private func download(_ tokenId:BigUInt) -> ObservablePromise<Media.IpfsImage?> {
#if os(macOS)
    return ObservablePromise(
      promise:self.ethContract.image(tokenId)
        .map {
          $0.flatMap {
            switch($0) {
            case .svg(let data):
              let svg = NFTYgoSVGImage(svg: String(data:data,encoding: .utf8)!)
              return Media.IpfsImage(image:.svg(svg),image_hd:.svg(svg))
            case .image(let data):
              guard let image = NSImage(data:data) else { return nil }
              return Media.IpfsImage(image:.image(image),image_hd:.image(image))
            }
          }
        }
    )
#else
    return imageCache.image(tokenId)
#endif
  }
  
  func getRecentTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
    return try! ethContract.transfer.wait().fetch(onDone:onDone) { log in
      
      let res = try! web3.eth.abi.decodeLog(event:Erc721Contract.Transfer,from:log);
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
    return try! ethContract.transfer.wait().updateLatest(onDone:onDone) { index,log in
      let res = try! web3.eth.abi.decodeLog(event:Erc721Contract.Transfer,from:log);
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
