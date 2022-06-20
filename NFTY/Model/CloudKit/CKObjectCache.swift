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
  let fallback : (_ in:Key) -> Promise<CKRecord?>
  let keyToString : (_ in:Key) -> String
  let set : (_ in:CKRecord,_ out:Output) -> Void
  let database : CKDatabase
  
  init(database:CKDatabase,entityName:String,keyField:String,fallback:@escaping (_ in:Key) -> Promise<CKRecord?>,keyToString: @escaping (_ in:Key) -> String, set:@escaping (_ in:CKRecord,_ out:Output) -> Void) {
    self.database = database
    self.entityName = entityName
    self.keyField = keyField
    self.fallback = fallback
    self.keyToString = keyToString
    self.set = set
  }
  
  private func onCacheMiss(_ key:Key) -> Promise<Output?> {
    return self.fallback(key)
      .then(on:DispatchQueue.global(qos:.userInteractive)) { record -> Promise<Output?> in
        guard let record = record else { return Promise.value(nil) }
        
        let output = Output(context: CoreDataManager.shared.managedContext)
        self.set(record,output)
        
        DispatchQueue.global(qos:.background).async {
          print("Saving recordId=\(self.keyToString(key))")
          try? CoreDataManager.shared.managedContext.save()
          self.database.save(record:record)
            .done(on:.global(qos: .background)) { result in
              print("Save returned for recordId=\(self.keyToString(key))")
            }
            .catch { print($0) }
        }
        return Promise.value(output)
      }
  }
  
  func get(_ key:Key) -> Promise<Output?> {
    let keyStr = self.keyToString(key)
    let request: NSFetchRequest<Output> = NSFetchRequest<Output>(entityName: entityName) as! NSFetchRequest<Output>
    request.predicate = NSPredicate(format: "\(keyField) == %@", keyStr)
    let results = try? CoreDataManager.shared.managedContext.fetch(request)
    print("Got results=\(String(describing: results)) for query=\(request)")
    
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
        self.set(record,output)
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
