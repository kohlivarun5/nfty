//
//  CKObjectCache.swift
//  NFTY
//
//  Created by Varun Kohli on 6/19/22.
//

import Foundation

import PromiseKit
import CoreData
import CloudKit

struct CKObjectCache<Key,Output:NSManagedObject> {
  
  let entityName : String
  let keyField : String
  let fallback : (_ in:Key, _ output:Output) -> Promise<Output?>
  let keyToString : (_ in:Key) -> String
  let database : CKDatabase
  
  init(
    database:CKDatabase,
    entityName:String,
    keyField:String,
    fallback:@escaping (_ in:Key, _ output:Output) -> Promise<Output?>,
    keyToString: @escaping (_ in:Key) -> String)
  {
    self.database = database
    self.entityName = entityName
    self.keyField = keyField
    self.fallback = fallback
    self.keyToString = keyToString
  }
  
  private func onCacheMiss(_ key:Key) -> Promise<Output?> {
    
    let output = Output(context: CoreDataManager.shared.managedContext)
    return self.fallback(key,output)
      .then(on:DispatchQueue.global(qos:.userInteractive)) { output -> Promise<Output?> in
        guard let output = output else { return Promise.value(nil) }
        
        try? CoreDataManager.shared.managedContext.save()
        
        DispatchQueue.global(qos:.background).async {
          let key = self.keyToString(key)
          let record = CKRecord(recordType: self.entityName, recordID:CKRecord.ID.init(recordName:key))
          
          record.setValuesForKeys(
            Dictionary(
              uniqueKeysWithValues:
                output.entity.attributesByName.keys
                .map {
                  ($0,output.value(forKey: $0) as! String?)
                }
            )
          )
          
          self.database.save(record:record)
            .done(on:.global(qos: .background)) { result in
              print("Save returned for recordId=\(key))")
            }
            .catch { print($0) }
        }
        return Promise.value(output)
      }
  }
  
  func get(_ key:Key) -> Promise<Output?> {
    let keyStr = self.keyToString(key)
    let request: NSFetchRequest<Output> = NSFetchRequest<Output>(entityName: entityName)
    request.predicate = NSPredicate(format: "\(keyField) == %@", keyStr)
    let results = try? CoreDataManager.shared.managedContext.fetch(request)
    // print("Got results=\(String(describing: results)) for query=\(request)")
    
    if let data = results?.first {
      return Promise.value(data)
    }
    
    return database.fetchRecordWithID(recordID:CKRecord.ID.init(recordName:keyStr))
      .map(on:DispatchQueue.global(qos:.userInteractive)) { result -> Output? in
        let (record,error) = result
        // print("Fetch returned with error=\(String(describing: error))")
        guard error == nil else { return nil }
        guard let record = record else { return nil }
        
        let output = Output(context: CoreDataManager.shared.managedContext)
        output.setValuesForKeys(
          Dictionary(
            uniqueKeysWithValues:
              record.allKeys().map { ($0,record[$0] as! String?) }
          )
        )
        try? CoreDataManager.shared.managedContext.save()
        return output
      }
      .then(on:DispatchQueue.global(qos:.userInteractive)) { (data:Output?) -> Promise<Output?> in
        switch(data) {
        case .some(let data):
          return Promise.value(data)
        case .none:
          return onCacheMiss(key)
        }
      }
    
  }
}
