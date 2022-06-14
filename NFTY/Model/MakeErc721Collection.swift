//
//  MakeErc721Collection.swift
//  NFTY
//
//  Created by Varun Kohli on 3/21/22.
//

import Foundation
import Web3
import PromiseKit
import CloudKit

struct MakeErc721Collection {
  
  static func ofName(name:String,address:EthereumAddress) -> Collection {
    return  Collection(
      info: CollectionInfo(
        address: address.hex(eip55: true),
        sample: "SAMPLE_ZUNK",
        name: name,
        webLink: nil,
        themeColor: .gunmetal,
        themeLabelColor: .white,
        disableRecentTrades: true,
        similarTokens: nil,
        rarityRanking: nil),
      contract: IpfsCollectionContract(
        name: name,
        address: address.hex(eip55: true), indicativePriceSource: .openSea)
    )
  }
  
  struct Erc721ContractInfo : Codable {
    let name : String
  }
  
  static private let KnownUnsupportedName = "com.nftygo.unsupported"
  
  static private func validateAddress(_ addressStr:String) -> Promise<Erc721ContractInfo?> {
    let address = try! EthereumAddress(hex: addressStr, eip55: true)
    let ethContract = Erc721Contract.EthContract(address.hex(eip55: true))
    // Confirm if it allows name, tokenUri, supportsInterface
    return ethContract.name().map {
      let nameOpt : String? = $0
      return nameOpt
    }
    .recover { e -> Promise<String?> in
      return Promise.value(nil)
    }
    .map {
      $0.map {
        return Erc721ContractInfo(name:$0)
      }
    }
  }
  
  static func ofAddress(address:EthereumAddress) -> Promise<Collection?> {
    
    let cache = CKJSONCache(
      database:CKContainer.default().publicCloudDatabase,
      bucket: "erc721Contracts",
      fallback:MakeErc721Collection.validateAddress)
    return cache.get(address.hex(eip55: true))
      .map { (info:Erc721ContractInfo?) -> Collection? in
        switch (info?.name) {
        case .none: return nil
        case .some(""): return nil
        case .some(MakeErc721Collection.KnownUnsupportedName): return nil
        case .some(let name): return MakeErc721Collection.ofName(name: name, address: address)
        }
      }
  }
  
}
