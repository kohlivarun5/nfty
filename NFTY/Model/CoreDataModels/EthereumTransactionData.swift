//
//  EthereumTransactionData.swift
//  NFTY
//
//  Created by Varun Kohli on 6/19/22.
//

import Foundation
import Web3
import CoreData
import PromiseKit
import CloudKit

extension EthereumTransactionData {
  public func set(_ tx:EthereumTransactionObject) {
    self.txHash = tx.hash.hex()
    self.value = tx.value.hex()
    self.to = tx.to?.hex(eip55: true)
    self.from = tx.from.hex(eip55: true)
    self.blockNumber = tx.blockNumber?.hex()
  }
}

extension EthereumTransactionData {
  static public func fetch(transactionHash:EthereumData,_ fallback: @escaping (_ transactionHash:EthereumData) -> Promise<EthereumTransactionObject?>) -> Promise<EthereumTransactionData?> {
    let request: NSFetchRequest<EthereumTransactionData> = EthereumTransactionData.fetchRequest()
    request.predicate = NSPredicate(format: "txHash == %@", transactionHash.hex())
    let results = try? CKPublicDataManager.shared.managedContext.fetch(request)
    print("Got results=\(results) for query=\(request)")
    switch(results?.first) {
    case .some(let data):
      return Promise.value(data)
    case .none:
      // Fetch and save and return
      return fallback(transactionHash)
        .map { tx -> EthereumTransactionData? in
          guard let tx = tx else { return nil }
          
          let txHash = tx.hash.hex()
          let record = CKRecord.init(recordType: "EthereumTransactionData", recordID:CKRecord.ID.init(recordName:txHash))
          record.setValuesForKeys([
            "txHash" : txHash,
            "value" : tx.value.hex(),
            "to" : (tx.to?.hex(eip55: true) : String?),
            "from" : (tx.from.hex(eip55: true) : String?),
            "blockNumber" : tx.blockNumber?.hex()
          ])
          print("Saving recordId=\(txHash)")
          CKContainer.default().publicCloudDatabase.save(record:record)
            .done(on:.global(qos: .background)) { result in
              print("Save returned for \(txHash)")
            }
            .catch { print($0) }
          let data = EthereumTransactionData(context: CKPublicDataManager.shared.managedContext)
          data.set(tx)
          return data
        }
    }
  }
}
