//
//  UserAccountOffers.swift
//  NFTY
//
//  Created by Varun Kohli on 2/24/22.
//

import Foundation
import PromiseKit
import Web3

struct UserAccountOffers {
  
  enum Kind {
    case sales
    case bids
    case offers
  }
  
  static private func openSeaQueryAddress(_ account:EthereumAddress,_ kind:Kind) -> (OpenSeaApi.QueryAddress,OpenSeaApi.Side) {
    switch(kind) {
    case .bids:
      return (.maker(account),OpenSeaApi.Side.buy)
    case .sales:
      return (.maker(account),OpenSeaApi.Side.sell)
    case .offers:
      return (.owner(account),OpenSeaApi.Side.buy)
    }
  }
  
  static private func nearBuyerReceiver(_ account:String?,_ kind:Kind) -> (String?,String?)? {
    
    switch(account,kind) {
    case (.none,_):
      return nil
    case (_,.bids):
      return (account,nil)
    case (_,.sales):
      return nil
    case (_,.offers):
      return (nil,account)
    }
  }
  
  static private func openSeaOffers(_ account:UserAccount,_ kind:Kind) -> Promise<[NFTToken]> {
    switch(account.ethAddress) {
    case .none:
      return Promise.value([])
    case .some(let ethAddress):
      let (address,side) = openSeaQueryAddress(ethAddress,kind)
      return OpenSeaApi.userOrders(address:address, side:side)
    }
  }
  
  static func getOffers(account:UserAccount,kind:Kind) -> Promise<[NFTToken]> {
    //print(account,kind)
    return openSeaOffers(account,kind)
      .then { openSeaTokens -> Promise<[NFTToken]> in
        
        switch(account.nearAccount,kind) {
        case (.none,_):
          return Promise.value(openSeaTokens)
        case (.some(let account),.bids):
          return ParasApi.offers(buyer_id:account,receiver_id: nil)
            .map { (result:ParasApi.Offers) -> [NFTToken] in
              
              result.data.results.compactMap { token in
                guard let tokenId = UInt(token.token_id) else { return nil }
                guard let price = (token.price.flatMap { (price:String) -> BigUInt? in
                  return BigUInt(price)
                }) else { return nil }
                let collection = NearCollection(address:token.contract_id)
                return NFTToken(
                  collection:collection,
                  nft: NFTWithLazyPrice(
                    nft: collection.contract.getNFT(BigUInt(tokenId)),
                    getPrice: {
                      ObservablePromise<NFTPriceStatus>(
                        resolved: NFTPriceStatus.known(
                          NFTPriceInfo(
                            near:price,
                            date:nil,
                            type:TradeEventType.bid)
                        )
                      )
                    })
                )
              } + openSeaTokens
            }
        case (.some(let account),.offers):
          return ParasApi.offers(buyer_id:nil,receiver_id: account)
            .map { (result:ParasApi.Offers) -> [NFTToken] in
              
              result.data.results.compactMap { token in
                guard let tokenId = UInt(token.token_id) else { return nil }
                guard let price = (token.price.flatMap { (price:String) -> BigUInt? in
                  return BigUInt(price)
                }) else { return nil }
                let collection = NearCollection(address:token.contract_id)
                return NFTToken(
                  collection:collection,
                  nft: NFTWithLazyPrice(
                    nft: collection.contract.getNFT(BigUInt(tokenId)),
                    getPrice: {
                      ObservablePromise<NFTPriceStatus>(
                        resolved: NFTPriceStatus.known(
                          NFTPriceInfo(
                            near:price,
                            date:nil,
                            type:TradeEventType.bid)
                        )
                      )
                    })
                )
              } + openSeaTokens
            }
        case (.some(let account),.sales):
          return ParasApi.token_for_sale(owner_id: account)
            .map { (result:ParasApi.Token) -> [NFTToken] in
              print("Found \(result.data.results.count) sales for \(account)");
              return result.data.results.compactMap { token in
                guard let tokenId = UInt(token.token_id) else { return nil }
                guard let price = (token.price.flatMap { BigUInt($0) }) else { return nil }
                let collection = NearCollection(address:token.contract_id)
                return NFTToken(
                  collection:collection,
                  nft: NFTWithLazyPrice(
                    nft: collection.contract.getNFT(BigUInt(tokenId)),
                    getPrice: {
                      ObservablePromise<NFTPriceStatus>(
                        resolved: NFTPriceStatus.known(
                          NFTPriceInfo(
                            near:price,
                            date:nil,
                            type:TradeEventType.ask)
                        )
                      )
                    })
                )
              } + openSeaTokens
            }
        }
      }
  }
  
}
