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
  
  private func createLocalFile(path:String,data: Data) -> URL {
    let tmpSubFolderURL = URL(fileURLWithPath: NSTemporaryDirectory())
    let fileURL = tmpSubFolderURL.appendingPathComponent(path.replacingOccurrences(of: "/", with: "."))
    try! data.write(to: fileURL)
    return fileURL
    
  }
  
  let bucket : String
  let fallback : (_ in:String) -> Promise<Output?>
  private var diskCache : DiskStorage<String,Output>
  
  let database : CKDatabase
  
  init(database:CKDatabase,bucket:String,fallback:@escaping (_ in:String) -> Promise<Output?>) {
    self.database = database
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
          let recordId = self.path(key)
          let record = CKRecord.init(recordType: "GenericJSONCache", recordID:CKRecord.ID.init(recordName:recordId))
          record.setValuesForKeys([jsonKey: CKAsset.init(fileURL: createLocalFile(path:recordId,data:jsonData))])
          print("Saving recordId=\(recordId)")
          self.database.save(record:record)
            .done(on:.global(qos: .background)) { result in
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
          
          let recordName = self.path(key)
          database.fetchRecordWithID(recordID:CKRecord.ID.init(recordName:recordName))
            .map(on:DispatchQueue.global(qos:.userInteractive)) { result -> Output? in
              let (record,error) = result
              // print("Fetch returned with error=\(String(describing: error))")
              
              guard error == nil else { return nil }
              
              guard let json = ((record?[jsonKey] as? CKAsset)?.fileURL.flatMap { try? Data(contentsOf:$0) }) else { return nil }
              guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else { return nil }
              let value = try? JSONDecoder().decode(Output.self, from: jsonData)
              return value
            }
            .then(on:DispatchQueue.global(qos:.userInteractive)) { (data:Output?) -> Promise<Output?> in
              switch(data) {
              case .some(let data):
                return Promise.value(data)
              case .none:
                return onCacheMiss(key)
              }
            }.map(on:DispatchQueue.global(qos:.userInteractive)) { data in
              DispatchQueue.global(qos:.background).async {
                data.flatMap { try? self.diskCache.setObject($0, forKey:key) }
              }
              return data
            }
            .done(seal.fulfill)
            .catch(seal.reject)
        }
      }
    }
  }
}
