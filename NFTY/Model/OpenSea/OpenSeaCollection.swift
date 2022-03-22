//
//  OpenSeaCollection.swift
//  NFTY
//
//  Created by Varun Kohli on 1/17/22.
//

import Foundation
import PromiseKit
import Web3



func openSeaCollection(address:String) -> Promise<Collection> {

  func erc721(address:String) -> Promise<Collection?> {
    switch(try? EthereumAddress(hex: address, eip55: false)) {
    case .some(let ethAddress):
      return MakeErc721Collection.ofAddress(address: ethAddress)
    case .none:
      return Promise.value(nil)
    }
  }
  
  return erc721(address: address)
    .then { collectionOpt -> Promise<Collection> in
      switch(collectionOpt) {
      case .some(let x):
        return Promise.value(x)
      case .none:
        return OpenSeaApiCore.getCollectionInfo(contract: address)
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
    }
}
