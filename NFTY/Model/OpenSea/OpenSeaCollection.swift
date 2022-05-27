//
//  OpenSeaCollection.swift
//  NFTY
//
//  Created by Varun Kohli on 1/17/22.
//

import Foundation
import PromiseKit
import Web3
import Cache

func erc721Collection(address:String) -> Promise<Collection?> {
  guard let ethAddress = try? EthereumAddress(hex: address, eip55: false) else { return Promise<Collection?>.value(nil) }
  return MakeErc721Collection.ofAddress(address: ethAddress)
}

func openSeaCollection(address:String) -> Promise<Collection> {
  
  OpenSeaApiCore.getCollectionInfo(contract: address)
    .map { info in
      Collection(
        info: CollectionInfo(
          address: address,
          sample: "glyph178",
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
