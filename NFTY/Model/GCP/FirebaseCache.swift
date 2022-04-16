//
//  FirebaseCache.swift
//  NFTY
//
//  Created by Varun Kohli on 4/16/22.
//

import Foundation
import Cache
import SwiftUI
import BigInt
import PromiseKit

struct FirebaseImageCache {
  
  let bucket : String
  let fallback : (_ tokenId:BigUInt) -> Promise<Data?>
  
  private let firebase = FirebaseCore()
  private var imageCache : DiskStorage<BigUInt,UIImage>
  private var imageCacheHD : DiskStorage<BigUInt,UIImage>
  
  init(bucket:String,fallback:@escaping (_ tokenId:BigUInt) -> Promise<Data?>) {
    self.bucket = bucket
    self.fallback = fallback
    self.imageCache = try! DiskStorage<BigUInt, UIImage>(
      config: DiskConfig(name: "\(bucket).ImageCacheSD",expiry: .never),
      transformer: TransformerFactory.forImage())
    self.imageCacheHD = try! DiskStorage<BigUInt, UIImage>(
      config: DiskConfig(name: "\(bucket).ImageCacheHD",expiry: .never),
      transformer: TransformerFactory.forImage())
  }
  
  
  private func path(_ tokenId:BigUInt) -> String {
    return "\(bucket)/\(tokenId)"
  }
  
  private func onCacheMiss(_ tokenId:BigUInt) -> Promise<Media.IpfsImage?> {
    return self.fallback(tokenId)
      .then { data -> Promise<Media.IpfsImage?> in
        switch(data) {
        case .none:
          return Promise.value(nil)
        case .some(let data):
          return firebase.putObject(path:self.path(tokenId), data)
            .map { return Media.IpfsImage.makeOpt(data) }
        }
      }
  }
  
  func image(_ tokenId:BigUInt) -> ObservablePromise<Media.IpfsImage?> {
    return ObservablePromise(promise: Promise { seal in
      DispatchQueue.global(qos:.userInteractive).async {
        switch(try? self.imageCache.object(forKey:tokenId),try? self.imageCacheHD.object(forKey:tokenId)) {
        case (.some(let image),.some(let image_hd)):
          seal.fulfill(Media.IpfsImage(image: image,image_hd: image_hd))
        case (.none,_),(_,.none):
          _ = firebase.getObject(path:self.path(tokenId))
            .then { (data:Data?) -> Promise<Media.IpfsImage?> in
              switch(data) {
              case .none:
                return onCacheMiss(tokenId)
              case .some(let data):
                return Promise.value(Media.IpfsImage.makeOpt(data))
              }
            }.done {
              $0.map { try? imageCache.setObject($0.image, forKey: tokenId) }
              $0.map { try? imageCacheHD.setObject($0.image_hd, forKey: tokenId) }
              seal.fulfill($0)
            }
        }
      }
    })
  }
}
