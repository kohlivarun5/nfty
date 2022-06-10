//
//  CKOwnerTokens.swift
//  NFTY
//
//  Created by Varun Kohli on 6/9/22.
//

import Foundation
import CloudKit
import PromiseKit
import Web3

struct CKOwnerTokens {
  
  struct Record {
    let owner : String
    let collectionAddress : String
    let tokenIds : [String]
    
    init(record:CKRecord) {
      self.owner = record["owner"] as! String
      self.collectionAddress = record["collectionAddress"] as! String
      self.tokenIds = record["tokenIds"] as! [String]
    }
    
    func toCKRecord() -> CKRecord {
      let record = CKRecord.init(recordType: "OwnerTokens")
      record.setValuesForKeys([
        "owner" : owner,
        "collectionAddress" : collectionAddress,
        "tokenIds" : tokenIds
      ])
      return record
    }
    
    func toNFT() -> Promise<(Collection,[NFTToken])> {
      return collectionsFactory
        .getByAddress(
          try! EthereumAddress(hex: self.collectionAddress, eip55: false)
            .hex(eip55: true))
        .map { collection -> (Collection,[NFTToken]) in
          
          let tokens = self.tokenIds
            .compactMap { UInt($0) }
            .map {
              NFTToken(
                collection: collection,
                nft: collection.contract.getToken($0))
            }
          return (collection,tokens)
        }
    }
  }
}
