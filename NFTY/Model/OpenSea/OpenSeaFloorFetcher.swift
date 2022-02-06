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
  let contractAddress : String
  let limit : UInt
  private var cursor : String?
  
  init(contractAddress:String,limit:UInt) {
    self.contractAddress = contractAddress
    self.limit = limit
  }
  
  func fetchNext() -> Promise<[NFTWithLazyPrice]> {
    OpenSeaApiCore.getCollectionInfo(contract:contractAddress)
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
  
  static func make(contractAddress:String) -> PagedTokensFetcher {
    return OpenSeaFloorFetcher(contractAddress:contractAddress,limit:40)
  }
  
}
