//
//  CollectionMetaData.swift
//  NFTY
//
//  Created by Varun Kohli on 6/19/22.
//

import Foundation
import Web3
import CoreData
import PromiseKit
import CloudKit

/*

extension CollectionMetaData {
  public func set(address:EthereumAddress,name:String) {
    self.name = name
    self.address = address.hex(eip55: true)
  }

  static public func fetch(address:EthereumAddress,_ fallback: @escaping (_ address:String) -> Promise<Erc721ContractInfo?>) -> Promise<CollectionMetaData?> {
    let addressStr = address.hex(eip55: true)
    let request: NSFetchRequest<CollectionMetaData> = CollectionMetaData.fetchRequest()
    request.predicate = NSPredicate(format: "address == %@", addressStr)
    let results = try? CKPublicDataManager.shared.managedContext.fetch(request)
    print("Got results=\(String(describing: results)) for query=\(request)")
    switch(results?.first) {
    case .some(let data):
      return Promise.value(data)
    case .none:
      // Fetch and save and return
      return fallback(addressStr)
        .map { info -> CollectionMetaData? in
          guard let info = info else { return nil }
          
          let data = CollectionMetaData(context: CKPublicDataManager.shared.managedContext)
          data.set(address:address,name:info.name)
          
          let record = CKRecord.init(recordType: "CollectionMetaData", recordID:CKRecord.ID.init(recordName:addressStr))
          record.setValuesForKeys([
            "address" : data.address,
            "name" : data.name
          ])
          print("Saving recordId=\(addressStr)")
 CKPublicDataManager.defaultContainer.publicCloudDatabase.save(record:record)
            .done(on:.global(qos: .background)) { result in
              print("Save returned for \(addressStr)")
            }
            .catch { print($0) }
          return data
        }
    }
  }
}
 */
