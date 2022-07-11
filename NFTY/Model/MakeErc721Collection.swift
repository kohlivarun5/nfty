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
  #if os(macOS)
    return  Collection(
      info: CollectionInfo(
        address: address.hex(eip55: true),
        sample: "SAMPLE_ZUNK",
        name: name,
        webLink: nil,
        themeColor: .black,
        themeLabelColor: .white,
        disableRecentTrades: true,
        similarTokens: nil,
        rarityRanking: nil),
      contract: IpfsCollectionContract(
        name: name,
        address: address.hex(eip55: true), indicativePriceSource: .openSea)
    )
    #else
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
    #endif
  }
  
  static private let KnownUnsupportedName = "com.nftygo.unsupported"
  
  private static var cache : [String:Erc721ContractInfo] = [:]
  
  public struct Erc721ContractInfo : Codable {
    let name : String?
  }
  
  static private func validateAddress(_ addressStr:String) -> Promise<Erc721ContractInfo?> {
    let address = try! EthereumAddress(hex: addressStr, eip55: true)
    let ethContract = Erc721Contract.EthContract(address.hex(eip55: true))
    // Confirm if it allows name, tokenUri, supportsInterface
    
    /*
     // Confirm if it allows name, tokenUri, supportsInterface
     return erc165.supportsInterface(interfaceId: "0x01ffc9a7") // https://eips.ethereum.org/EIPS/eip-165 : ERC165
     .then { supportsSupportsInterface -> Promise<Bool> in
     if (!supportsSupportsInterface) { return Promise.value(false) }
     return erc165.supportsInterface(interfaceId:"0x5b5e139f") // https://eips.ethereum.org/EIPS/eip-721 : ERC721Metadata
     }.then { isErc721 -> Promise<Bool> in
     if (!isErc721) { return Promise.value(false) }
     return erc165.supportsInterface(interfaceId:"0x80ac58cd") // https://eips.ethereum.org/EIPS/eip-721 : ERC721
     }.then { isErc721 -> Promise<String?> in
     if (!isErc721) { return Promise.value(nil) }*/
    
    return ethContract.name().map {
      let nameOpt : String? = $0
      return nameOpt
    }
    .recover { e -> Promise<String?> in
      print("Error = \(e)")
      return Promise.value(nil)
    }
    .map(on:.global(qos: .userInteractive)) {
      let ret = Erc721ContractInfo(name:$0)
      MakeErc721Collection.cache[addressStr] = ret
      return ret
    }
  }

#if !os(macOS)
  private static var collectionCache = CKObjectCache(
    database: CKPublicDataManager.defaultContainer.publicCloudDatabase,
    entityName: "CollectionMetaData",
    keyField: "address",
    fallback: { (address:String,output:CollectionMetaData) in
      return MakeErc721Collection.validateAddress(address)
        .map {
          guard let info = $0 else { return nil }
          output.address = address
          output.name = info.name
          return output
        }
    },
    keyToString: { $0 }
  )

  
  static func ofAddress(address:EthereumAddress) -> Promise<Collection?> {
    
    let addressStr = address.hex(eip55: true)
    
    if let info = cache[addressStr] {
      return Promise.value(info.name.map { MakeErc721Collection.ofName(name:$0,address: address) })
    }
    
    return collectionCache.get(addressStr)
      .map { (info:CollectionMetaData?) -> Collection? in
        switch (info?.name) {
        case .none: return nil
        case .some(""): return nil
        case .some(MakeErc721Collection.KnownUnsupportedName): return nil
        case .some(let name): return MakeErc721Collection.ofName(name: name, address: address)
        }
      }
  }
#endif
  
}
