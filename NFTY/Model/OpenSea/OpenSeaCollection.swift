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

private var collectionNameCache = try! DiskStorage<String, String>(
  config: DiskConfig(name: "erc721CollectionNameCache",expiry: .never),
  transformer:TransformerFactory.forCodable(ofType:String.self))

func erc721Collection(address:String) -> Promise<Collection?> {
  
  guard let ethAddress = try? EthereumAddress(hex: address, eip55: false) else { return Promise<Collection?>.value(nil) }
  
  switch(try? collectionNameCache.object(forKey: address)) {
  case .some(let name):
    switch(name) {
    case "":
      return Promise.value(nil)
    default:
      return Promise.value(MakeErc721Collection.ofName(name: name, address: ethAddress))
    }
  default:
    return MakeErc721Collection.ofAddress(address: ethAddress)
      .map {
        try? collectionNameCache.setObject($0?.info.name ?? "", forKey: address)
        return $0
      }
  }
}

func openSeaCollection(address:String) -> Promise<Collection> {
  
  OpenSeaApiCore.getCollectionInfo(contract: address)
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
