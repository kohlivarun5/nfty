//
//  FirebaseCore.swift
//  NFTY
//
//  Created by Varun Kohli on 4/16/22.
//

import Foundation
import FirebaseStorage

import PromiseKit

struct FirebaseCore {
  
  private let maxSize = 8 * 1024 * 1024
  
  private func getStorage() async -> Storage {
    let storage = Storage.storage(url:"gs://nfty-1bfd4.appspot.com")
  }
  
  func putObject(path:String, _ data:Data) -> Promise<Void>{
    return Promise { seal in
    // Upload the file to the path "images/rivers.jpg"
    getStorage().reference(withPath:path).putData(data, metadata: nil) { (metadata, error) in
      seal.fulfill()
    }.resume()                                                        key: key, metadata: nil)) else { return }
  }
  
  func getObject(path:String) async -> Promise<Data?> {
    return Promise { seal in
      getStorage().reference(withPath:path).getData(maxSize:maxSize) { data, error in
        if let error = error {
          print(error)
          seal.fulfill(nil)
        } else {
          seal.fulfill(data)
        }
      }
    }
  }  
}
