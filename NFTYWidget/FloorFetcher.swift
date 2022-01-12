//
//  FloorFetcher.swift
//  NFTY
//
//  Created by Varun Kohli on 1/11/22.
//

import Foundation
import PromiseKit

struct CollectionStats : Identifiable {
  let id : String
  let name : String
  let floorPrice : Double
  let change : Double
  let changeSince : Date
}

func fetchStats() -> Promise<[CollectionStats]> {
  
  let storage = WidgetStorage()
  
  guard let address = storage.walletAddress else {
    return Promise.value([])
  }
  
  
  return COLLECTIONS
    .reduce(Promise<[(Collection,[NFTWithLazyPrice])]>.value([]), { accu,collection in
      accu.then { accuTokens in
        return Promise { seal in
          var tokens : [NFTWithLazyPrice] = []
          collection.data.contract.getOwnerTokens(
            address: address,
            onDone: {
              seal.fulfill(accuTokens + [(collection,tokens)])
            },
            { tokens.append($0)})
        }
      }
    })
    .map {
      // Filter collections user doesn't own
      $0
        .filter { !$0.1.isEmpty }
        .map { $0.0 }
    }
    .then {
      // Fetch floor for each collection
      $0.reduce(Promise<[(Collection,Double?)]>.value([]), { accu,collection in
        accu
          .then { accu in
            collection.data.contract.indicativeFloor().map { accu + [(collection,$0)] }
          }
      })
    }
    .map { $0.filter { $0.1 != .none } }
    .map {
      $0.map {
        CollectionStats(
          id: $0.0.data.contract.contractAddressHex,
          name: $0.0.info.name,
          floorPrice: $0.1!,
          change: 0,
          changeSince: Date.now)
      }
    }
}
