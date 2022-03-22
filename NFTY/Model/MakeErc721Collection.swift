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
  
  static func ofAddress(address:EthereumAddress) -> Promise<Collection?> {
    
    // Confirm if it allows name, tokenUri, supportsInterface
    
    let erc165 = ERC165Contract(address:address)
    
    return erc165.supportsInterface(interfaceId: "0x01ffc9a7") // https://eips.ethereum.org/EIPS/eip-165 : ERC165
      .then { supportsSupportsInterface -> Promise<Bool> in
        if (!supportsSupportsInterface) { return Promise.value(false) }
        
        return erc165.supportsInterface(interfaceId:"0x5b5e139f") // https://eips.ethereum.org/EIPS/eip-721 : ERC721Metadata
        
      }.then { isErc721 -> Promise<String?> in
        if (!isErc721) { return Promise.value(nil) }
        
        let ethContract = Erc721Contract.EthContract(address.hex(eip55: true))
        return ethContract.name().map {
          let nameOpt : String? = $0
          return nameOpt
        }
        
      }.map { name -> Collection? in
        
        name.map { name in
        
          Collection(
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
              address: address.hex(eip55: true), indicativePriceSource: .openSea
            )
          )
          
        }
        
      }
  }
  
}
