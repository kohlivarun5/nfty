//
//  FirebaseJSONCache.swift
//  NFTY
//
//  Created by Varun Kohli on 4/22/22.
//

import Foundation
import Cache
import PromiseKit
import FirebaseDatabase

struct FirebaseJSONCache<Output:Codable> {
  
  let bucket : String
  let fallback : (_ in:String) -> Promise<Output?>
  private var diskCache : DiskStorage<String,Output>
  
  let firebase : DatabaseReference!
  
  init(bucket:String,fallback:@escaping (_ in:String) -> Promise<Output?>) {
    self.firebase = Database.database().reference()
    self.bucket = bucket
    self.fallback = fallback
    self.diskCache = try! DiskStorage<String, Output>(
      config: DiskConfig(name: "\(bucket).diskCache",expiry: .never),
      transformer: TransformerFactory.forCodable(ofType: Output.self))
  }
  
  
  private func path(_ key:String) -> String {
    return "\(bucket)/\(key)"
  }
  
  private func onCacheMiss(_ key:String) -> Promise<Output?> {
    return self.fallback(key)
      .then(on:DispatchQueue.global(qos:.userInteractive)) { data -> Promise<Output?> in
        guard let data = data else { return Promise.value(nil) }
        let jsonData = try JSONEncoder().encode(data)
        let dict = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments)
        self.firebase.child(self.path(key)).setValue(dict)
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
            self.firebase.child(self.path(key)).getData(completion:  { error, snapshot in
              guard error == nil else { return seal.fulfill(nil) }
              guard let json = snapshot.value as? [String:Any] else { return seal.fulfill(nil) }
              guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else { return seal.fulfill(nil) }
              let value = try? JSONDecoder().decode(Output.self, from: jsonData)
              seal.fulfill(value)
            })
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
