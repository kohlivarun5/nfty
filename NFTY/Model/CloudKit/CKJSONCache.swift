//
//  CKJSONCache.swift
//  NFTY
//
//  Created by Varun Kohli on 6/8/22.
//

import Foundation

import Cache
import PromiseKit
import CloudKit

struct CKJSONCache<Output:Codable> {
  
  let bucket : String
  let fallback : (_ in:String) -> Promise<Output?>
  private var diskCache : DiskStorage<String,Output>
  
  let databse : CKDatabase
  
  init(database:CKDatabase,bucket:String,fallback:@escaping (_ in:String) -> Promise<Output?>) {
    self.databse = database
    self.bucket = bucket
    self.fallback = fallback
    self.diskCache = try! DiskStorage<String, Output>(
      config: DiskConfig(name: "\(bucket).diskCache",expiry: .never),
      transformer: TransformerFactory.forCodable(ofType: Output.self))
  }
  
  private let jsonKey = "json"
  
  
  private func path(_ key:String) -> String {
    return "\(bucket)/\(key)"
  }
  
  private func onCacheMiss(_ key:String) -> Promise<Output?> {
    return self.fallback(key)
      .then(on:DispatchQueue.global(qos:.userInteractive)) { data -> Promise<Output?> in
        guard let data = data else { return Promise.value(nil) }
        let jsonData = try JSONEncoder().encode(data)
        
        DispatchQueue.global(qos:.background).async {
          let recordId = self.path(tokenId)
          let record = CKRecord.init(recordType: "GenericJSONCache", recordID:CKRecord.ID.init(recordName:recordId))
          record.setValuesForKeys([jsonKey: jsonData])
          print("Saving recordId=\(recordId)")
          database.save(record:record)
            .done { result in
              print("Save returned for \(recordId)")
            }
            .catch { print($0) }
        }
        return Promise.value(data)
      }
  }
  
  
  func get(_ key:String) -> Promise<Output?> {
    return Promise { seal in
      DispatchQueue.global(qos:.userInteractive).async {
        switch(try? self.diskCache.object(forKey:key)) {
        case .some(let data):
          return seal.fulfill(data)
        case .none:
          Promise { seal in
            database.fetchRecordWithID(recordID:CKRecord.ID.init(recordName:recordName))
              .map(on:DispatchQueue.global(qos:.userInteractive)) { result -> Output? in
                let (record,error) = result
                print("Fetch returned with error=\(String(describing: error))")
                
                guard error == nil else { return nil }
                
                guard let json = record[jsonKey] as? Data else { return nil }
                guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else { return nil }
                let value = try? JSONDecoder().decode(Output.self, from: jsonData)
                return value
              }
          }
          .then(on:DispatchQueue.global(qos:.userInteractive)) { (data:Output?) -> Promise<Output?> in
            switch(data) {
            case .some(let data):
              return Promise.value(data)
            case .none:
              return onCacheMiss(key)
            }
          }.map(on:DispatchQueue.global(qos:.userInteractive)) {
            let _ = $0.flatMap { try? self.diskCache.setObject($0, forKey:key) }
            return $0
          }
          .done(seal.fulfill)
          .catch(seal.reject)
        }
      }
    }
  }
}
