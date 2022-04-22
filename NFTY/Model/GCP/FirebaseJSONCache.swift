//
//  FirebaseJSONCache.swift
//  NFTY
//
//  Created by Varun Kohli on 4/22/22.
//

import Foundation
import Cache
import PromiseKit
import FirebaseFirestore

struct FirebaseJSONCache<Output:Codable> {
  
  let bucket : String
  let fallback : (_ in:String) -> Promise<Output?>
  private var diskCache : DiskStorage<String,Output>
  
  let firebase = Firestore
  
  init(bucket:String,fallback:@escaping (_ in:String) -> Promise<Output?>) {
    self.firebase = Firestore.firestore()
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
        self.firebase.document(self.path(key)).setData(try! JSONEncoder().encode(data))
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
            self.firebase.document(self.path(key)).getDocument { (document, error) in
              if let document = document, document.exists {
                seal.fulfill(try? JSONDecoder().decode(Output.self, from: document.data()))
              } else {
                seal.fulfill(nil)
              }
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
