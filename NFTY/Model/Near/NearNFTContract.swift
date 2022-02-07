//
//  NearNFTContract.swift
//  NFTY
//
//  Created by Varun Kohli on 1/27/22.
//

import Foundation
import BigInt
import PromiseKit
import Cache
import UIKit
import Web3

class NearNFTContract : ContractInterface {
  
  var contractAddressHex: String
  var account_id : String
  let name : String
  let nearContract : NearNFT
  
  private var imageCache : DiskStorage<BigUInt,UIImage>
  private var imageCacheHD : DiskStorage<BigUInt,UIImage>
  
  init(name:String,account_id:String) {
    self.name = name
    self.account_id = account_id
    self.nearContract = NearNFT(account_id: account_id)
    self.contractAddressHex = "NearNFT@\(account_id)"
    self.imageCache = try! DiskStorage<BigUInt, UIImage>(
      config: DiskConfig(name: "\(contractAddressHex).ImageCache",expiry: .never),
      transformer: TransformerFactory.forImage())
    self.imageCacheHD = try! DiskStorage<BigUInt, UIImage>(
      config: DiskConfig(name: "\(contractAddressHex).ImageCacheHD",expiry: .never),
      transformer: TransformerFactory.forImage())
  }
  
  func getRecentTrades(onDone: @escaping () -> Void, _ response: @escaping (NFTWithPrice) -> Void) {
    onDone()
  }
  
  func refreshLatestTrades(onDone: @escaping () -> Void, _ response: @escaping (NFTWithPrice) -> Void) {
    onDone()
  }
  
  private static func imageOfData(_ data:Data?) -> Media.IpfsImage? {
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
  
  private func fetchImage(_ tokenId:BigUInt) -> Promise<Data?> {
    return self.nearContract.nft_metadata()
      .then { metadata in
        self.nearContract.nft_token(token_id: tokenId)
          .map { token in (metadata,token) }
      }
      .then(on: DispatchQueue.global(qos:.userInitiated)) { (metadata,token) -> Promise<Data?> in
        
        let uri = metadata.base_uri.flatMap { baseUri in
          token.metadata.media.flatMap { media in "\(baseUri)/\(media)" }
        }
        
        return Promise { seal in
          switch(
            uri
              .map { $0.replacingOccurrences(of: "ipfs://", with: "https://ipfs.infura.io:5001/api/v0/cat?arg=") }
              .flatMap { URL(string:$0) }
          ) {
          case .none:
            seal.reject(NSError(domain:"", code:404, userInfo:nil))
          case .some(let url):
            var request = URLRequest(url:url)
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
  
  private func download(_ tokenId:BigUInt) -> ObservablePromise<Media.IpfsImage?> {
    return ObservablePromise(promise: Promise { seal in
      DispatchQueue.global(qos:.userInteractive).async {
        switch(try? self.imageCache.object(forKey:tokenId),try? self.imageCacheHD.object(forKey:tokenId)) {
        case (.some(let image),.some(let image_hd)):
          seal.fulfill(Media.IpfsImage(image: image,image_hd: image_hd))
        case (.none,_),(_,.none):
          self.fetchImage(tokenId)
            .done(on:DispatchQueue.global(qos: .background)) {
              let image = NearNFTContract.imageOfData($0)
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
  
  func getNFT(_ tokenId: UInt) -> NFT {
    NFT(
      address: self.contractAddressHex,
      tokenId: tokenId,
      name: name,
      media: .ipfsImage(
        Media.IpfsImageLazy(
          tokenId:BigUInt(tokenId),
          download : self.download)
      )
    )
  }
  
  func getToken(_ tokenId: UInt) -> NFTWithLazyPrice {
    NFTWithLazyPrice(nft: self.getNFT(tokenId), getPrice: {
      return ObservablePromise(resolved: NFTPriceStatus.burnt)
    })
  }
  
  func ownerOf(_ tokenId: UInt) -> Promise<EthereumAddress?> {
    return Promise.value(nil)
  }
  
  func getOwnerTokens(address: EthereumAddress, onDone: @escaping () -> Void, _ response: @escaping (NFTWithLazyPrice) -> Void) {
    onDone()
  }
  
  func getEventsFetcher(_ tokenId: UInt) -> TokenEventsFetcher? {
    return nil
  }
  
  func indicativeFloor() -> Promise<Double?> {
    return Promise.value(nil)
  }
  
  var vaultContract: CollectionVaultContract? = nil
  
  var tradeActions: TokenTradeInterface? = nil
    
  func floorFetcher() -> PagedTokensFetcher? { nil }
  
}
