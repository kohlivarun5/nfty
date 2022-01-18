//
//  FloorFetcher.swift
//  NFTY
//
//  Created by Varun Kohli on 1/11/22.
//

import Foundation
import PromiseKit

struct CollectionFloorData : Identifiable {
  let id : String
  let name : String
  let floorPrice : Double
}

func fetchStats() -> Promise<[CollectionFloorData]> {
  
  let storage = WidgetStorage()
  
  guard let address = storage.walletAddress else {
    return Promise.value([])
  }
  
  
  return OpenSeaApi.getOwnerTokens(address: address)
    .then {
      $0.reduce(Promise<[Collection]>.value([]), { accu,token in
        accu.map { accu in
          if (accu.contains { $0.info.address == token.collection.info.address }) {
            return accu
          } else {
            return (accu + [token.collection])
          }
        }
      })
        .then {
          // Fetch floor for each collection
          $0.reduce(Promise<[(Collection,Double?)]>.value([]), { accu,collection in
            accu
              .then { accu in
                collection.contract.indicativeFloor().then { floor in
                  after(seconds: 0.2).map { _ in accu + [(collection,floor)] }
                }
              }
          })
        }
        .map {
          $0.compactMap { info in info.1.map { (info.0,$0) } }
        }
        .map {
          $0.map {
            CollectionFloorData(
              id: $0.0.contract.contractAddressHex,
              name: $0.0.info.name,
              floorPrice: $0.1)
          }
        }
    }
}
