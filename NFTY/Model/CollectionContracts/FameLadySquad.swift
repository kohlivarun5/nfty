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


class FameLadySquad_Contract : ContractInterface {
  
  private func imageUrl(_ tokenId:UInt) -> URL? {
    return URL(string:"https://nft-1.mypinata.cloud/ipfs/QmRRRcbfE3fTqBLTmmYMxENaNmAffv7ihJnwFkAimBP4Ac/\(tokenId).png")
  }
  
  private var pricesCache : [UInt : ObservablePromise<NFTPriceStatus>] = [:]
  
  let name = "FameLadySquad"
  
  let contractAddressHex = "0xf3E6DbBE461C6fa492CeA7Cb1f5C5eA660EB1B47"
  let ethContract = Erc721Contract(address:"0xf3E6DbBE461C6fa492CeA7Cb1f5C5eA660EB1B47")
  
  func getEventsFetcher(_ tokenId: UInt) -> TokenEventsFetcher? {
    return ethContract.getEventsFetcher(tokenId)
  }
  
  func getRecentTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
    return ethContract.transfer.fetch(onDone:onDone) { log in
      
      let res = try! web3.eth.abi.decodeLog(event:self.ethContract.Transfer,from:log);
      let tokenId = UInt(res["tokenId"] as! BigUInt);
      
      let onPrice = { (indicativePriceWei:BigUInt?) in
        
        if let price = priceIfNotZero(indicativePriceWei) {
          response(NFTWithPrice(
            nft:NFT(
              address:self.contractAddressHex,
              tokenId:tokenId,
              name:self.name,
              media:.image(MediaImageEager(self.imageUrl(tokenId)!))),
            indicativePriceWei:NFTPriceInfo(
              price:price,
              blockNumber:log.blockNumber?.quantity)
          ))
        }
      };
      
      self.ethContract.eventOfTx(transactionHash:log.transactionHash,eventType:.bought)
        .done(on:DispatchQueue.global(qos:.userInteractive)) {
          onPrice($0?.value)
        }.catch { error in
          print(error);
          onPrice(nil)
        }
    }
  }
  
  func refreshLatestTrades(onDone: @escaping () -> Void,_ response: @escaping (NFTWithPrice) -> Void) {
    return ethContract.transfer.updateLatest(onDone:onDone) { log in
      let res = try! web3.eth.abi.decodeLog(event:self.ethContract.Transfer,from:log);
      let tokenId = UInt(res["tokenId"] as! BigUInt);
      
      let onPrice = { (indicativePriceWei:BigUInt?) in
        
        if let price = priceIfNotZero(indicativePriceWei) {
          response(NFTWithPrice(
            nft:NFT(
              address:self.contractAddressHex,
              tokenId:tokenId,
              name:self.name,
              media:.image(MediaImageEager(self.imageUrl(tokenId)!))),
            indicativePriceWei:NFTPriceInfo(
              price:price,
              blockNumber:log.blockNumber?.quantity)
          ))
        }
      };
      
      self.ethContract.eventOfTx(transactionHash:log.transactionHash,eventType:.bought)
        .done(on:DispatchQueue.global(qos:.userInteractive)) {
          onPrice($0?.value)
        }.catch { error in
          print(error);
          onPrice(nil)
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
          media:.image(MediaImageEager(self.imageUrl(tokenId)!))),
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
