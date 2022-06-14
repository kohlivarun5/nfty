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
    
    static let recordType : String = "OwnerCollectionTokens"
    
    let owner : String
    let collectionAddress : String
    let tokenIds : [String]
    
    init(owner:String,collectionAddress:String,tokenIds:[String]) {
      self.owner = owner
      self.collectionAddress = collectionAddress
      self.tokenIds = tokenIds
    }
    
    init(record:CKRecord) {
      self.owner = record["owner"] as! String
      self.collectionAddress = record["collectionAddress"] as! String
      self.tokenIds = record["tokenIds"] as! [String]
    }
    
    func toCKRecord() -> CKRecord {
      let recordId = CKRecord.ID(recordName: "\(owner)/\(collectionAddress)")
      let record = CKRecord.init(recordType: Record.recordType,recordID: recordId)
      record.setValuesForKeys([
        "owner" : owner,
        "collectionAddress" : collectionAddress,
        "tokenIds" : tokenIds
      ])
      return record
    }
    
    func toNFT() -> Promise<(Collection,[NFTToken])?> {
      return collectionsFactory
        .getByAddressOpt(
          try! EthereumAddress(hex: self.collectionAddress, eip55: false)
            .hex(eip55: true))
        .map(on:.global(qos: .userInteractive)) { collection -> (Collection,[NFTToken])? in
          
          guard let collection = collection else { return nil }
          
          let tokenIds = self.tokenIds
            .compactMap { UInt($0) }
          
          let tokens = tokenIds.map {
            NFTToken(
              collection: collection,
              nft: collection.contract.getToken($0))
          }
          
          return (collection,tokens)
        }
    }
  }
  
}
