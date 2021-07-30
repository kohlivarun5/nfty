//
//  FameLadySquad.swift
//  NFTY
//
//  Created by Varun Kohli on 7/18/21.
//

import Foundation
import Cache
import BigInt
import PromiseKit
import Web3
import Web3ContractABI
import UIKit


class FameLadySquad_Contract : ContractInterface {
  
  private var imageCache = try! DiskStorage<BigUInt, Media.IpfsImage>(
    config: DiskConfig(name: "FameLadySquad.ImageCache",expiry: .never),
    transformer: TransformerFactory.forCodable(ofType: Media.IpfsImage.self))
  
  private var pricesCache : [UInt : ObservablePromise<NFTPriceStatus>] = [:]
  
  let name = "FameLadySquad"
  
  let contractAddressHex = "0xf3E6DbBE461C6fa492CeA7Cb1f5C5eA660EB1B47"
  
  var tradeActions: TokenTradeInterface? = OpenSeaTradeApi(contract: try! EthereumAddress(hex: "0xf3E6DbBE461C6fa492CeA7Cb1f5C5eA660EB1B47", eip55: false))
  
  class IpfsImageEthContract : Erc721Contract {
    
    // till 4443 inclusive, it is QmRRRcbfE3fTqBLTmmYMxENaNmAffv7ihJnwFkAimBP4Ac
    // after it is QmTwNwAerqdP3LXcZnCCPyqQzTyB26R5xbsqEy5Vh3h6Dw
    
    func image(_ tokenId:BigUInt) -> Promise<Media.IpfsImage?> {
      return Promise { seal in
        
        let url = tokenId < 4444
          ? URL(string:"https://nft-1.mypinata.cloud/ipfs/QmRRRcbfE3fTqBLTmmYMxENaNmAffv7ihJnwFkAimBP4Ac/\(tokenId).png")!
          : URL(string:"https://nft-1.mypinata.cloud/ipfs/QmTwNwAerqdP3LXcZnCCPyqQzTyB26R5xbsqEy5Vh3h6Dw/\(tokenId).png")!
        
        var request = URLRequest(url:url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request,completionHandler:{ data, response, error -> Void in
          // print(data,response,error)
          
          // Compress these images on download, as they cause jitter in UI scrolling
          
          DispatchQueue.global(qos:.userInteractive).async {
            data.map {
              let image = UIImage(data:$0)!
              let data = image.jpegData(compressionQuality: 0.1)!
              seal.fulfill(Media.IpfsImage(data: data))
            }
          }
        }).resume()
      }
    }
  }
  
  private func download(_ tokenId:BigUInt) -> ObservablePromise<Media.IpfsImage?> {
    switch(try? imageCache.object(forKey:tokenId)) {
    case .some(let p):
      return ObservablePromise(resolved: p)
    case .none:
      let p = ethContract.image(tokenId);
      let observable = ObservablePromise(promise: p) { image in
        DispatchQueue.global(qos:.userInteractive).async {
          image.flatMap {
            try? self.imageCache.setObject($0, forKey: tokenId)
          }
        }
      }
      return observable
    }
  }
  
  
  let ethContract = IpfsImageEthContract(address:"0xf3E6DbBE461C6fa492CeA7Cb1f5C5eA660EB1B47")
  
  func getEventsFetcher(_ tokenId: UInt) -> TokenEventsFetcher? {
    return ethContract.getEventsFetcher(tokenId)
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
