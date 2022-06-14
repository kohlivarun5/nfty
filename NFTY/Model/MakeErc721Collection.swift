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
  
  private static var cache : [String:Erc721ContractInfo] = [:]
  
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
    .map(on:.global(qos: .userInteractive)) {
      $0.map {
        let ret = Erc721ContractInfo(name:$0)
        MakeErc721Collection.cache[addressStr] = ret
        return ret
      }
    }
  }
  
  static func ofAddress(address:EthereumAddress) -> Promise<Collection?> {
    
    let addressStr = address.hex(eip55: true)
    
    if let info = cache[addressStr] {
      return Promise.value(MakeErc721Collection.ofName(name:info.name,address: address))
    }
    
    let cache = CKJSONCache(
      database:CKContainer.default().publicCloudDatabase,
      bucket: "erc721Contracts",
      fallback:MakeErc721Collection.validateAddress)
    return cache.get(addressStr)
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
