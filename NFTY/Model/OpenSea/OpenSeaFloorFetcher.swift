//
//  OpenSeaFloorFetcher.swift
//  NFTY
//
//  Created by Varun Kohli on 2/6/22.
//

import Foundation
import Web3
import PromiseKit

class OpenSeaFloorFetcher : PagedTokensFetcher {
  let collection : Collection
  let limit : UInt
  private var cursor : String?
  
  init(collection:Collection,limit:UInt) {
    self.collection = collection
    self.limit = limit
  }
  
  func fetchNext() -> Promise<[NFTWithLazyPrice]> {
    
    OpenSeaApiCore.getCollectionInfo(contract:self.collection.contract.contractAddressHex)
      .then(on:.global(qos: .userInteractive)) { (info:OpenSeaApiCore.CollectionInfo) -> Promise<[NFTWithLazyPrice]> in
        switch(info.slug) {
        case .some(let slug):
          let query = OpenSeaGQL.assetSearchQuery(collection:slug, cursor:self.cursor,limit:self.limit)
          return OpenSeaGQL.call(query:query)
            .map(on:.global(qos: .userInteractive)) { (result:OpenSeaGQL.QueryResult) -> [NFTWithLazyPrice] in
              self.cursor = result.search.pageInfo.endCursor
              return result.search.edges.map { (edge:OpenSeaGQL.QueryResult.Search.Edge) -> NFTWithLazyPrice in
                
                let contract = self.collection.contract
                
                return NFTWithLazyPrice(
                  nft: contract.getNFT(BigUInt(edge.node.asset.tokenId)!),
                  getPrice: {
                    return ObservablePromise(
                      resolved:NFTPriceStatus.known(
                        NFTPriceInfo(wei: BigUInt(edge.node.asset.orderData.bestAsk.paymentAssetQuantity.quantityInEth),
                                     date: nil,
                                     type: TradeEventType.ask)
                      )
                    )
                  }
                )
              }
            }
        case .none:
          return Promise.value([])
        }
      }
  }
  
  static func make(collection:Collection) -> PagedTokensFetcher {
    return OpenSeaFloorFetcher(collection:collection,limit:20)
  }
  
}
