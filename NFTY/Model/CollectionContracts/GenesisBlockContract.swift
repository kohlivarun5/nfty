//
//  GenesisBlockContract.swift
//  NFTY
//
//  Created by Varun Kohli on 9/18/21.
//

import Foundation

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


class GenesisBlockContract : ContractInterface {
  
  class EthContract : Erc721Contract {
    
    struct TokenUriData : Codable {
      let image : String
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
      return Promise { seal in
        
        var request = URLRequest(
          url:URL(string: "https://genesisblocks.art/api/tokens/\(tokenId)")!)
        request.httpMethod = "GET"
        
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
                let url = URL(string:try JSONDecoder().decode(TokenUriData.self, from: data).image)!
                print(url)
                seal.fulfill(url)
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
      }.then(on: DispatchQueue.global(qos:.userInitiated)) { (uriData:URL) -> Promise<Data?> in
        
        return Promise { seal in
          
          var request = URLRequest(url:uriData)
          request.httpMethod = "GET"
          
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
  private var pricesCache : [UInt : ObservablePromise<NFTPriceStatus>] = [:]
  private var imageCache : DiskStorage<BigUInt,UIImage>
  
  let name : String
  let contractAddressHex : String
  var ethContract : EthContract
  
  var tradeActions: TokenTradeInterface?
  
  init(name:String,address:String) {
    self.imageCache = try! DiskStorage<BigUInt, UIImage>(
      config: DiskConfig(name: "\(name).ImageCache",expiry: .seconds(60)),
      transformer: TransformerFactory.forImage())
    self.name = name
    self.contractAddressHex = address
    self.ethContract = EthContract(address:address)
    self.tradeActions = OpenSeaTradeApi(contract: try! EthereumAddress(hex: contractAddressHex, eip55: false))
  }
  
  func getEventsFetcher(_ tokenId: BigUInt) -> TokenEventsFetcher? {
    return ethContract.getEventsFetcher(tokenId)
  }
  
  private func download(_ tokenId:BigUInt) -> ObservablePromise<Media.IpfsImage?> {
    
    return ObservablePromise(promise: Promise { seal in
      DispatchQueue.global(qos:.userInteractive).async {
        try? self.imageCache.removeExpiredObjects()
        switch(try? self.imageCache.object(forKey:tokenId)) {
        /* case .some(let image):
          seal.fulfill(Media.IpfsImage(image: image))
         case .none: */ default:
          self.ethContract.image(tokenId)
            .done(on:DispatchQueue.global(qos: .background)) {
              let image = EthContract.imageOfData($0)
              image.flatMap {
                try? self.imageCache.setObject($0.image, forKey: tokenId)
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
          media:.ipfsImage(Media.IpfsImageLazy(tokenId:tokenId, download: self.download))
        ),
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
          media:.ipfsImage(Media.IpfsImageLazy(tokenId:tokenId, download: self.download))
        ),
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
      media:.ipfsImage(Media.IpfsImageLazy(tokenId:tokenId, download: self.download))
    )
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
  
  func ownerOf(_ tokenId: BigUInt) -> Promise<UserAccount?> {
    return ethContract.ownerOf(tokenId)
  }
  
  func indicativeFloor() -> Promise<PriceUnit?> {
    return AlchemyApi.GetFloor.indicativeFloor(self.contractAddressHex)
  }
 
  var vaultContract: CollectionVaultContract? = nil
  
  func floorFetcher(_ collection:Collection) -> PagedTokensFetcher? {
    return OpenSeaFloorFetcher.make(collection:collection)
  }
  
}
