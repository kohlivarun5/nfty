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


class IpfsCollectionContract : ContractInterface {
  
  class IpfsImageEthContract : Erc721Contract {
    
    struct TokenUriData : Codable {
      let image : String
    }
    
    static func imageOfData(_ data:Data?) -> Media.IpfsImage? {
      return data
        .flatMap { UIImage(data:$0) }
        .flatMap { $0.jpegData(compressionQuality: 0.1) }
        .flatMap { UIImage(data:$0) }
        .map { Media.IpfsImage(image:$0) }
    }
    
    func image(_ tokenId:BigUInt) -> Promise<Data?> {
      return ethContract.tokenURI(tokenId:tokenId)
        .then(on: DispatchQueue.global(qos:.userInteractive)) { (uri:String) -> Promise<TokenUriData> in
          
          return Promise { seal in
            
            var request = URLRequest(
              url:URL(string: uri.replacingOccurrences(
                        of: "ipfs://",
                        with: "https://ipfs.infura.io:5001/api/v0/cat?arg="))!)
            request.httpMethod = "GET"
            
            print("calling \(request.url!)")
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
          
        }.then(on: DispatchQueue.global(qos:.userInitiated)) { (uriData:TokenUriData) -> Promise<Data?> in
          
          return Promise { seal in
            
            var request = URLRequest(
              url:URL(string:uriData.image.replacingOccurrences(of: "ipfs://", with: "https://ipfs.infura.io:5001/api/v0/cat?arg="))!)
            request.httpMethod = "GET"
            
            print("calling \(request.url!)")
            URLSession.shared.dataTask(with: request,completionHandler:{ data, response, error -> Void in
              // print(data,response,error)
              seal.fulfill(data)
            }).resume()
          }
        }
    }
  }
  
  private var imageCache : DiskStorage<BigUInt,UIImage>
  private var pricesCache : [UInt : ObservablePromise<NFTPriceStatus>] = [:]
  
  let web3 : Web3
  
  let name : String
  let contractAddressHex : String
  var ethContract : IpfsImageEthContract
  
  var tradeActions: TokenTradeInterface?
  
  init(name:String,address:String) {
    self.imageCache = try! DiskStorage<BigUInt, UIImage>(
      config: DiskConfig(name: "\(name).ImageCache",expiry: .never),
      transformer: TransformerFactory.forImage())
    self.name = name
    self.contractAddressHex = address
    self.ethContract = IpfsImageEthContract(address:address)
    self.tradeActions = OpenSeaTradeApi(contract: try! EthereumAddress(hex: contractAddressHex, eip55: false))
  }
  
  func getEventsFetcher(_ tokenId: UInt) -> TokenEventsFetcher? {
    return ethContract.getEventsFetcher(tokenId)
  }
  
  private func download(_ tokenId:BigUInt) -> ObservablePromise<Media.IpfsImage?> {
    return ObservablePromise(promise: Promise { seal in
      DispatchQueue.global(qos:.userInteractive).async {
        switch(try? self.imageCache.object(forKey:tokenId)) {
        case .some(let image):
          seal.fulfill(Media.IpfsImage(image: image))
        case .none:
          self.ethContract.image(tokenId)
            .done(on:DispatchQueue.global(qos: .background)) {
              let image = IpfsImageEthContract.imageOfData($0)
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
      
      let res = try! Web3ABI.decodeLog(event:self.ethContract.Transfer,from:log);
      let tokenId = UInt(res["tokenId"] as! BigUInt);
      let isMint = res["from"] as! EthereumAddress == EthereumAddress(hexString: "0x0000000000000000000000000000000000000000")!
      
      response(NFTWithPrice(
        nft:NFT(
          address:self.contractAddressHex,
          tokenId:tokenId,
          name:self.name,
          media:.ipfsImage(Media.IpfsImageLazy(tokenId:BigUInt(tokenId), download: self.download))),
        blockNumber: log.blockNumber?.quantity,
        indicativePriceWei:.lazy {
          ObservablePromise(
            promise:
              self.ethContract.eventOfTx(transactionHash:log.transactionHash,eventType:isMint ? .minted : .bought)
              .map {
                let price = priceIfNotZero($0?.value);
                return NFTPriceStatus.known(
                  NFTPriceInfo(
                    price:price,
                    blockNumber:log.blockNumber?.quantity,
                    type: isMint ? .minted : price.map { _ in TradeEventType.bought } ?? TradeEventType.transfer))
              }
          )
        }
      ))
    }
  }
  
  func refreshLatestTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
    return ethContract.transfer.updateLatest(onDone:onDone) { index,log in
      let res = try! Web3ABI.decodeLog(event:self.ethContract.Transfer,from:log);
      let tokenId = UInt(res["tokenId"] as! BigUInt);
      let isMint = res["from"] as! EthereumAddress == EthereumAddress(hexString: "0x0000000000000000000000000000000000000000")!
      
      response(NFTWithPrice(
        nft:NFT(
          address:self.contractAddressHex,
          tokenId:tokenId,
          name:self.name,
          media:.ipfsImage(Media.IpfsImageLazy(tokenId:BigUInt(tokenId), download: self.download))),
        blockNumber: log.blockNumber?.quantity,
        indicativePriceWei:.lazy {
          ObservablePromise(
            promise:
              self.ethContract.eventOfTx(transactionHash:log.transactionHash,eventType:isMint ? .minted : .bought)
              .map {
                let price = priceIfNotZero($0?.value);
                return NFTPriceStatus.known(
                  NFTPriceInfo(
                    price:price,
                    blockNumber:log.blockNumber?.quantity,
                    type: isMint ? .minted : price.map { _ in TradeEventType.bought } ?? TradeEventType.transfer))
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
      media:.ipfsImage(Media.IpfsImageLazy(tokenId:BigUInt(tokenId), download: self.download)))
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
  
}


class IpfsWithOpenSea : IpfsCollectionContract {
  
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
      
      print("calling \(request.url!)")
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
  
  
  override func getOwnerTokens(address: EthereumAddress, onDone: @escaping () -> Void, _ response: @escaping (NFTWithLazyPrice) -> Void) {
    getOwnerTokensFromOpenSea(address:address)
      .map(on:DispatchQueue.global(qos:.userInteractive)) { (tokenIds:[UInt]) -> [Void] in
        return tokenIds.map { response(self.getToken($0)) }
      }.done(on:DispatchQueue.global(qos:.userInteractive)) { (promises:[Void]) -> Void in
        onDone()
      }.catch {
        print ($0)
        onDone()
      }
  }
}
