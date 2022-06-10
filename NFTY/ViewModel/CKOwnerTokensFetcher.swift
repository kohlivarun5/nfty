//
//  CKOwnerTokensFetcher.swift
//  NFTY
//
//  Created by Varun Kohli on 6/9/22.
//

import Foundation
import Web3
import CloudKit
import PromiseKit

struct CKOwnerTokensFetcher {
  
  static func saveOwnerTokens(database:CKDatabase,owner:EthereumAddress,tokens:[NFTToken]) {
    
    let grouped = Dictionary(grouping: tokens, by: { $0.collection.contract.contractAddressHex })
    
    let records = grouped.map { (collectionAddress,tokens) in
      CKOwnerTokens.Record(
        owner: owner.hex(eip55: true), collectionAddress: collectionAddress,
        tokenIds: tokens.map { String($0.nft.nft.tokenId) }
      )
    }
    
    reduce_p(records, (), { _,record in
      database.save(record:record.toCKRecord())
        .map { result in print("Saved record=\(record) with result=\(result)") }
    })
    .catch { print($0) }
    return ()
  }
  
  class Loader {
    enum State {
      case uninitialized
      case cursor(CKQueryOperation.Cursor)
      case finished
    }
    
    let database : CKDatabase
    let owner : EthereumAddress
    private var state : State = .uninitialized
    private let limit : Int = 5
    
    init(database:CKDatabase,owner:EthereumAddress) {
      self.database = database
      self.owner = owner
    }
    
    func fetch() -> Promise<[(Collection,[NFTToken])]> {
      switch state {
      case .uninitialized:
        let query = CKQuery(
          recordType: CKOwnerTokens.Record.recordType,
          predicate: NSPredicate(format: "owner == %@",owner.hex(eip55: true)))
        
        return Promise { seal in
          database.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: limit) { result in
            switch result {
            case .failure(let error):
              seal.reject(error)
            case .success((let results,let cursor)):
              switch(cursor) {
              case .some(let cursor):
                self.state = .cursor(cursor)
              case .none:
                self.state = .finished
              }
              
              reduce_p(results, [], { accu,result in
                let (_,result) = result
                switch result {
                case .failure:
                  return Promise.value(accu)
                case .success(let record):
                  let record = CKOwnerTokens.Record(record: record)
                  return record.toNFT().map { nfts in accu + [nfts] }
                }
              })
              .done { seal.fulfill($0) }
              .catch { seal.reject($0) }
            }
          }
        }
      case .cursor(let cursor):
        return Promise { seal in
          database.fetch(withCursor: cursor, desiredKeys: nil, resultsLimit: limit) { result in
            switch result {
            case .failure(let error):
              seal.reject(error)
            case .success((let results,let cursor)):
              switch(cursor) {
              case .some(let cursor):
                self.state = .cursor(cursor)
              case .none:
                self.state = .finished
              }
              
              reduce_p(results, [], { accu,result in
                let (_,result) = result
                switch result {
                case .failure:
                  return Promise.value(accu)
                case .success(let record):
                  let record = CKOwnerTokens.Record(record: record)
                  return record.toNFT().map { nfts in accu + [nfts] }
                }
              })
              .done { seal.fulfill($0) }
              .catch { seal.reject($0) }
            }
          }
        }
      case .finished:
        return Promise.value([])
      }
    }
  }
}
