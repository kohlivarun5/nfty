//
//  OpenSeaCollection.swift
//  NFTY
//
//  Created by Varun Kohli on 1/17/22.
//

import Foundation
import PromiseKit


func openSeaCollection(address:String) -> Promise<CompositeRecentTradesObject.CollectionInitializer> {
  
  return OpenSeaApi.getCollectionInfo(contract: address)
    .map { info in
      CompositeRecentTradesObject.CollectionInitializer(
        info: CollectionInfo(
          address: address,
          sample: "SampleBAYC1",//info.image_url,
          name: info.name,
          webLink: info.external_url,
          themeColor: .gunmetal,
          themeLabelColor: .white,
          disableRecentTrades: true,
          similarTokens: nil,
          rarityRanking: nil),
        contract: IpfsCollectionContract(name: info.name, address: address, indicativePriceSource: .openSea))
    }
}
