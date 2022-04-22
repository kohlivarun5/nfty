//
//  MakeErc721Collection.swift
//  NFTY
//
//  Created by Varun Kohli on 3/21/22.
//

import Foundation
import Web3
import PromiseKit

struct MakeErc721Collection {
  
  static func ofName(name:String,address:EthereumAddress) -> Collection {
    return  Collection(
      info: CollectionInfo(
        address: address.hex(eip55: true),
        sample: "SAMPLE_ABS",
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
    let erc165 = ERC165Contract(address:address)
    
    // Confirm if it allows name, tokenUri, supportsInterface
    return erc165.supportsInterface(interfaceId: "0x01ffc9a7") // https://eips.ethereum.org/EIPS/eip-165 : ERC165
      .then { supportsSupportsInterface -> Promise<Bool> in
        if (!supportsSupportsInterface) { return Promise.value(false) }
        return erc165.supportsInterface(interfaceId:"0x5b5e139f") // https://eips.ethereum.org/EIPS/eip-721 : ERC721Metadata
      }.then { isErc721 -> Promise<Bool> in
        if (!isErc721) { return Promise.value(false) }
        return erc165.supportsInterface(interfaceId:"0x80ac58cd") // https://eips.ethereum.org/EIPS/eip-721 : ERC721
      }.then { isErc721 -> Promise<String?> in
        if (!isErc721) { return Promise.value(nil) }
        
        let ethContract = Erc721Contract.EthContract(address.hex(eip55: true))
        return ethContract.name().map {
          let nameOpt : String? = $0
          return nameOpt
        }
        
      }
      .recover { e -> Promise<String?> in
        return Promise.value(nil)
      }
      .map {
        switch($0) {
        case .none:
          return Erc721ContractInfo(name:MakeErc721Collection.KnownUnsupportedName)
        case .some(let name):
          return Erc721ContractInfo(name:name)
        }
      }
  }
  
  static func ofAddress(address:EthereumAddress) -> Promise<Collection?> {
        
    let cache = FirebaseJSONCache(bucket: "erc721Contracts", fallback:MakeErc721Collection.validateAddress)
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
