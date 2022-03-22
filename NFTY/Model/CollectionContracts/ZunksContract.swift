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


class ZunksContract : ContractInterface {
  
  class IpfsImageEthContract : Erc721Contract {
    
    struct TokenUriData : Codable {
      let image_url : String
    }
    
    static func imageOfData(_ data:Data?) -> Media.IpfsImage? {
      return data
        .flatMap {
          UIImage(data:$0)
            .flatMap { image_hd in
              image_hd
                .jpegData(compressionQuality: 0.1)
                .flatMap { UIImage(data:$0) }
                .map { Media.IpfsImage(image:$0,image_hd:image_hd) }
            }
        }
    }
    
    func image(_ tokenId:BigUInt) -> Promise<Data?> {
      return ethContract.tokenURI(tokenId:tokenId)
        .then(on: DispatchQueue.global(qos:.userInteractive)) { (uri:String) -> Promise<TokenUriData> in
          
          return Promise { seal in
            let url = URL(string: ipfsUrl(uri))!
            var request = URLRequest(url:url)
            request.httpMethod = url.host.map { $0 == "ipfs.infura.io" ? "POST" : "GET"} ?? "GET"
            
            print("calling \(request.url!)")
            ImageLoadingSemaphore.wait()
            URLSession.shared.dataTask(with: request,completionHandler:{ data, response, error -> Void in
              // print(data,response,error)
              ImageLoadingSemaphore.signal()
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
          
        }.then(on: DispatchQueue.global(qos:.userInitiated)) { (uriData:TokenUriData) -> Promise<Data?> in
          
          return Promise { seal in
            let url = URL(string:ipfsUrl(uriData.image_url))!
            var request = URLRequest(
              url:url)
            request.httpMethod = url.host.map { $0 == "ipfs.infura.io" ? "POST" : "GET"} ?? "GET"
            
            print("calling \(request.url!)")
            ImageLoadingSemaphore.wait()
            URLSession.shared.dataTask(with: request,completionHandler:{ data, response, error -> Void in
              // print(data,response,error)
              ImageLoadingSemaphore.signal()
              seal.fulfill(data)
            }).resume()
          }
        }
    }
  }
  
  private var imageCache : DiskStorage<BigUInt,UIImage>
  private var imageCacheHD : DiskStorage<BigUInt,UIImage>
  private var pricesCache : [UInt : ObservablePromise<NFTPriceStatus>] = [:]
  
  let name : String
  let contractAddressHex : String
  var ethContract : IpfsImageEthContract
  
  var tradeActions: TokenTradeInterface?
  
  init(name:String,address:String) {
    self.imageCache = try! DiskStorage<BigUInt, UIImage>(
      config: DiskConfig(name: "\(name).ImageCache",expiry: .never),
      transformer: TransformerFactory.forImage())
    
    self.imageCacheHD = try! DiskStorage<BigUInt, UIImage>(
      config: DiskConfig(name: "\(name).ImageCacheHD",expiry: .never),
      transformer: TransformerFactory.forImage())
    
    self.name = name
    self.contractAddressHex = address
    self.ethContract = IpfsImageEthContract(address:address)
    self.tradeActions = OpenSeaTradeApi(contract: try! EthereumAddress(hex: contractAddressHex, eip55: false))
  }
  
  func getEventsFetcher(_ tokenId: BigUInt) -> TokenEventsFetcher? {
    return ethContract.getEventsFetcher(tokenId)
  }
  
  private func download(_ tokenId:BigUInt) -> ObservablePromise<Media.IpfsImage?> {
    return ObservablePromise(promise: Promise { seal in
      DispatchQueue.global(qos:.userInteractive).async {
        switch(try? self.imageCache.object(forKey:tokenId),try? self.imageCacheHD.object(forKey:tokenId)) {
        case (.some(let image),.some(let image_hd)):
          seal.fulfill(Media.IpfsImage(image: image,image_hd: image_hd))
        case (_,.none),(.none,_):
          self.ethContract.image(tokenId)
            .done(on:DispatchQueue.global(qos: .background)) {
              let image = IpfsImageEthContract.imageOfData($0)
              image.flatMap {
                try? self.imageCache.setObject($0.image, forKey: tokenId)
                try? self.imageCacheHD.setObject($0.image_hd, forKey: tokenId)
              }
              seal.fulfill(image)
            }
            .catch {
              print($0)
              seal.fulfill(nil)
            }
        }
      }
    })
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
        blockNumber:log.blockNumber.map { .ethereum($0) },
        indicativePrice:.lazy {
          ObservablePromise(
            promise:
              self.ethContract.eventOfTx(transactionHash:log.transactionHash,eventType:isMint ? .minted : .bought)
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
        blockNumber:log.blockNumber.map { .ethereum($0) },
        indicativePrice:.lazy {
          ObservablePromise(
            promise:
              self.ethContract.eventOfTx(transactionHash:log.transactionHash,eventType:isMint ? .minted : .bought)
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
    return OpenSeaApi.getCollectionStats(contract:self.contractAddressHex)
      .map { stats in stats?.floor_price }
  }
  
  var vaultContract: CollectionVaultContract? = nil
  
  func floorFetcher(_ collection:Collection) -> PagedTokensFetcher? {
    return OpenSeaFloorFetcher.make(collection: collection)
  }
  
}
