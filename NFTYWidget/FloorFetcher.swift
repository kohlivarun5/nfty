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
  
  
  
  return fetchAllOwnerTokens(address: address, accu:[], offset: 0, foundMax: false)
    .then {
      $0.reduce(Promise<[(Collection,UInt)]>.value([]), { accu,token in
        accu.map { accu in
          
          switch(accu.firstIndex { $0.0.info.address == token.collection.info.address}) {
          case .none:
            return (accu + [(token.collection,UInt(1))])
          case .some(let index):
            var newAccu = accu;
            newAccu[index] = (newAccu[index].0,newAccu[index].1+1);
            return newAccu
          }
        }
      })
        .then {
          // Fetch floor for each collection
          $0.reduce(Promise<[(Collection,UInt,Double?)]>.value([]), { accu,item in
            let (collection,count) = item;
            return accu
              .then { accu in
                collection.contract.indicativeFloor().then { floor in
                  after(seconds: 0.5).map { _ in accu + [(collection,count,floor)] }
                }
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
              ownedCount:$0.1,
              floorPrice: $0.2)
          }
        }
    }
}
