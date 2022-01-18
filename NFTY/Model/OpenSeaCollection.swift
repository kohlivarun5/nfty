//
//  OpenSeaCollection.swift
//  NFTY
//
//  Created by Varun Kohli on 1/17/22.
//

import Foundation
import PromiseKit


func openSeaCollection(address:String) -> Promise<Collection> {
  
  return OpenSeaApi.getCollectionInfo(contract: address)
    .map { info in
      Collection(
        info: CollectionInfo(
          address: address,
          sample: "SAMPLE_ABS",
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
