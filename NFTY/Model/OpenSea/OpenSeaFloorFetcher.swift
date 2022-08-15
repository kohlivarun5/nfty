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
  private var isDone : Bool = false
  
  init(collection:Collection,limit:UInt) {
    self.collection = collection
    self.limit = limit
  }
  
  func fetchNext() -> Promise<[NFTWithLazyPrice]> {
    guard !self.isDone else { return Promise.value([]) }
    
    return OpenSeaApiCore.getCollectionInfo(contract:self.collection.contract.contractAddressHex)
      .then(on:.global(qos: .userInteractive)) { (info:OpenSeaApiCore.CollectionInfo) -> Promise<[NFTWithLazyPrice]> in
        switch(info.slug) {
        case .some(let slug):
          let query = OpenSeaGQL.assetSearchQuery(collection:slug, cursor:self.cursor,limit:self.limit)
          return OpenSeaGQL.call(query:query)
            .map(on:.global(qos: .userInteractive)) { (result:OpenSeaGQL.QueryResult) -> [NFTWithLazyPrice] in
              if (result.search.pageInfo.endCursor == nil) { self.isDone = true }
              self.cursor = result.search.pageInfo.endCursor
              return result.search.edges.compactMap { (edge:OpenSeaGQL.QueryResult.Search.Edge) -> NFTWithLazyPrice? in
                
                let contract = self.collection.contract
                
                guard let ask = edge.node.asset.orderData.bestAsk else { return nil }
                
                let quantityInEth = ask.paymentAssetQuantity.quantityInEth ?? (
                  ask.paymentAssetQuantity.asset.symbol == "ETH" || ask.paymentAssetQuantity.asset.symbol == "WETH"
                  ? ask.paymentAssetQuantity.quantity : nil);
                
                guard let quantityInEth = quantityInEth else { return nil }
                
                return NFTWithLazyPrice(
                  nft: contract.getNFT(BigUInt(edge.node.asset.tokenId)!),
                  getPrice: {
                    return ObservablePromise(
                      resolved:NFTPriceStatus.known(
                        NFTPriceInfo(wei: BigUInt(quantityInEth),
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
