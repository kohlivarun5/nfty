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
  
  private let maxSize : Int64 = 8 * 1024 * 1024
  
  private func getStorage() -> Storage {
    return Storage.storage(url:"gs://nfty-1bfd4.appspot.com")
  }
  
  func putObject(path:String, _ data:Data) -> Promise<Void>{
    return Promise { seal in
      // Upload the file to the path "images/rivers.jpg"
      DispatchQueue.global(qos:.userInteractive).async {
        print("Calling firebase for PUT:\(path)")
        getStorage().reference(withPath:path).putData(data, metadata: nil) { (metadata, error) in
          seal.fulfill(())
        }.resume()
      }
    }
  }
  
  func getObject(path:String) -> Promise<Data?> {
    return Promise { seal in
      DispatchQueue.global(qos:.userInitiated).async {
        print("Calling firebase for GET:\(path)")
        getStorage().reference(withPath:path).getData(maxSize:maxSize) { data, error in
          if let _ = error {
            // print(error)
            seal.fulfill(nil)
          } else {
            seal.fulfill(data)
          }
        }.resume()
      }
    }
  }
}
