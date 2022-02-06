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
  let collection : EthereumAddress
  let limit : UInt
  private var cursor : String?
  
  init(collection:EthereumAddress,limit:UInt) {
    self.collection = collection
    self.limit = limit
  }
  
  func fetchNext() -> Promise<[NFTWithLazyPrice]> {
    OpenSeaApiCore.getCollectionInfo(contract: collection.hex(eip55: true))
      .then { (info:OpenSeaApiCore.CollectionInfo) -> Promise<[NFTWithLazyPrice]> in
        switch(info.slug) {
        case .some(let slug):
          let query = OpenSeaGQL.assetSearchQuery(collection:slug, cursor:self.cursor,limit:self.limit)
          return OpenSeaGQL.call(query:query)
            .map { (result:OpenSeaGQL.QueryResult) -> [NFTWithLazyPrice] in
              self.cursor = result.search.pageInfo.endCursor
              return result.search.edges.map { (edge:OpenSeaGQL.QueryResult.Search.Edge) -> NFTWithLazyPrice in
                
                let contract = IpfsCollectionContract(
                  name: edge.node.asset.collection.name,
                  address: edge.node.asset.assetContract.address,
                  indicativePriceSource: .openSea)
                
                return NFTWithLazyPrice(
                  nft: contract.getNFT(UInt(edge.node.asset.tokenId)!),
                  getPrice: {
                    return ObservablePromise(
                      resolved:NFTPriceStatus.known(
                        NFTPriceInfo(price: BigUInt(edge.node.asset.orderData.bestAsk.paymentAssetQuantity.quantityInEth),
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
  
  static func make(collection:EthereumAddress) -> PagedTokensFetcher {
    return OpenSeaFloorFetcher(collection:collection,limit:40)
  }
  
}
