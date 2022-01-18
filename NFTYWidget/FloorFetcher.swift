//
//  FloorFetcher.swift
//  NFTY
//
//  Created by Varun Kohli on 1/11/22.
//

import Foundation
import PromiseKit
import Web3

struct CollectionFloorData : Identifiable {
  let id : String
  let name : String
  let floorPrice : Double
}

func fetchAllOwnerTokens(address:EthereumAddress,accu:[NFTToken],offset:Int,foundMax:Bool) -> Promise<[NFTToken]> {
  if (foundMax) { return Promise.value(accu) }
  let limit = 40
  
  return after(seconds:0.5).then { _ in
    OpenSeaApi.getOwnerTokens(address: address,offset:offset,limit:limit)
      .then { tokens in
        fetchAllOwnerTokens(address: address,accu:accu + tokens,offset:offset+limit,foundMax:tokens.isEmpty)
      }
  }
}

func fetchStats() -> Promise<[CollectionFloorData]> {
  
  let storage = WidgetStorage()
  
  guard let address = storage.walletAddress else {
    return Promise.value([])
  }
  
  // Need a way to fetch all
  
  
  
  return fetchAllOwnerTokens(address: address, accu:[], offset: 0, foundMax: false)
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
                  after(seconds: 0.5).map { _ in accu + [(collection,floor)] }
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
