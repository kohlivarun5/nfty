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
  let ownedCount : UInt
  let floorPrice : PriceUnit
}

func fetchAllOwnerTokens(tokens:NftOwnerTokens) -> Promise<[(Collection,[NFTToken])]> {
  
  if (tokens.foundMax) { return Promise.value(tokens.tokens) }
  
  return after(seconds:0.5).then { _ in
    return Promise { seal in
      tokens.load() {
        fetchAllOwnerTokens(tokens:tokens)
          .done {
            seal.fulfill($0)
          }
          .catch {
            seal.reject($0)
          }
      }
    }
  }
}

func fetchStats() -> Promise<[CollectionFloorData]> {
  
  let storage = WidgetStorage()
  
  let account = storage.userAccount()
  
  print("fetchStats account=\(account)")
  return fetchAllOwnerTokens(tokens:getOwnerTokens(account))
    .map { $0.map { ($0.0,$0.1.count) } }
    .then { items -> Promise<[(Collection,Int,PriceUnit?)]> in
      return reduce_p(items,[], { accu,item in
        let (collection,count) = item;
        return after(seconds: 0.2).then { _ -> Promise<PriceUnit?> in
            collection.contract.indicativeFloor()
          }.map { floor in
            accu + [(collection,count,floor)]
          }.recover { error -> Promise<[(Collection,Int,PriceUnit?)]> in
            print(error)
            return Promise.value(accu)
          }
      })
    }
    .map {
      $0.compactMap { info in info.2.map { (info.0,info.1,$0) } }
    }
    .map {
      $0.map {
        CollectionFloorData(
          id: $0.0.contract.contractAddressHex,
          name: $0.0.info.name,
          ownedCount:UInt($0.1),
          floorPrice: $0.2)
      }
    }
}
