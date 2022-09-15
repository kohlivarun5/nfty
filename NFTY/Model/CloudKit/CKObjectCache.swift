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

struct CKObjectCache<Key,Data,Output:NSManagedObject> {
  
  let entityName : String
  let keyField : String
  let fallback: (_ in:Key) -> Promise<Data?>
  let output:  (_ data:Data, _ output: inout Output) -> Void
  let data:  (_ output:Output) -> Data?
  let keyToString : (_ in:Key) -> String
  let database : CKDatabase
  
  init(
    database:CKDatabase,
    entityName:String,
    keyField:String,
    fallback:@escaping (_ in:Key) -> Promise<Data?>,
    output:@escaping (_ data:Data, _ output:inout Output) -> Void,
    data:@escaping (_ output:Output) -> Data?,
    keyToString: @escaping (_ in:Key) -> String)
  {
    self.database = database
    self.entityName = entityName
    self.keyField = keyField
    self.fallback = fallback
    self.output = output
    self.data = data
    self.keyToString = keyToString
  }
  
  private func onCacheMiss(_ key:Key) -> Promise<Data?> {
    
    return self.fallback(key)
      .then(on:DispatchQueue.global(qos:.userInteractive)) { data -> Promise<Data?> in
        guard let data = data else { return Promise.value(nil) }
        
        CoreDataManager.shared.persistentContainer.performBackgroundTask { backgroundContext in
          var output = Output(context: backgroundContext)
          self.output(data,&output)
          try? backgroundContext.save()
          
          
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
        return Promise.value(data)
      }
  }
  
  func get(_ key:Key) -> Promise<Data?> {
    
    return Promise { seal in
      
      CoreDataManager.shared.persistentContainer.performBackgroundTask { backgroundContext in
        let keyStr = self.keyToString(key)
        
          // print("Fetching from coreData \(entityName):\(keyStr)")
        let request: NSFetchRequest<Output> = NSFetchRequest<Output>(entityName: entityName)
        request.predicate = NSPredicate(format: "\(keyField) == %@", keyStr)
        let results = try? backgroundContext.fetch(request)
          // print("Got results=\(String(describing: results)) for query=\(request)")
        
        if let data = results?.first {
          return seal.fulfill(self.data(data))
        }
        
          // print("Failed to find in coredata \(entityName):\(keyStr)")
        database.fetchRecordWithID(recordID:CKRecord.ID.init(recordName:keyStr))
          .then(on:DispatchQueue.global(qos:.userInteractive)) { result -> Promise<Data?> in
            let (record,error) = result
              // print("Fetch returned with error=\(String(describing: error))")
            guard error == nil else { return Promise.value(nil) }
            guard let record = record else { return Promise.value(nil) }
            
            return Promise { seal in
              
              print("*** Failed to find in coredata \(entityName):\(keyStr), but found in CloudKit")
              CoreDataManager.shared.persistentContainer.performBackgroundTask { backgroundContext in
                let output = Output(context: backgroundContext)
                output.setValuesForKeys(
                  Dictionary(
                    uniqueKeysWithValues:
                      record.allKeys().map { ($0,record[$0] as! String?) }
                  )
                )
                try? backgroundContext.save()
                seal.fulfill(self.data(output))
              }
            }
          }
          .then(on:DispatchQueue.global(qos:.userInteractive)) { (data:Data?) -> Promise<Data?> in
            switch(data) {
            case .some(let data):
              return Promise.value(data)
            case .none:
              return onCacheMiss(key)
            }
          }
          .done { seal.fulfill($0) }
          .catch { seal.reject($0) }
      }
      
    }
  }
}
