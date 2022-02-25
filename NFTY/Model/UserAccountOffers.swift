//
//  UserAccountOffers.swift
//  NFTY
//
//  Created by Varun Kohli on 2/24/22.
//

import Foundation
import PromiseKit

struct UserAccountOffers {
  
  enum Side {
    case buy
    case sell
  }
  
  static private func openSeaSide(_ side:Side) -> OpenSeaApi.Side {
    switch(side) {
    case .buy:
      return OpenSeaApi.Side.buy
    case .sell:
      return OpenSeaApi.Side.sell
    }
  }
  
  private func buyerReceiver(_ side:Side,_ account:String) -> (String?,String?) {
    switch(side) {
    case .buy:
      return (account,nil)
    case .sell:
      return (nil,account)
    }
  }
  
  static func getOffers(account:UserAccount,side:Side) -> Promise<[NFTToken]> {
    
    return OpenSeaApi.userOrders(address: account.ethAddress, side: UserAccountOffers.openSeaSide((side)))
      .then { openSeaTokens in
        
        switch(account.nearAccount) {
        case .none:
          return Promise.value(openSeaTokens)
        case .some(let account):
          let (buyer_id,receiver_id) = buyerReceiver(side,account)
          return ParasApi.offers(buyer_id:buyer_id,receiver_id: receiver_id)
            .map { (result:ParasApi.Offers) -> [NFTToken] in
              
              result.data.results.map {
                guard let tokenId = UInt(token.token_series_id) else { return nil }
                let collection = NearCollection(address:token.contract_id)
                return NFTToken(
                  collection:collection,
                  nft: collection.contract.getToken(tokenId))
              } + openSeaTokens
            }
        }
      }
  }
  
}
