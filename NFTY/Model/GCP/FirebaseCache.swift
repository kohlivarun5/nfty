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
  
  struct Images {
    let sd : UIImage
    let hd : UIImage
  }
  
  let bucket : String
  
  private let firebase = FirebaseCore()
  
  private var imageCache : DiskStorage<BigUInt,Media.IpfsImage>
  
  let fallback : (_ tokenId:BigUInt) -> Promise<Data?>
  
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

  func image(_ tokenId:BigUInt) -> Promise<Media.IpfsImage?> {
    switch(try? self.imageCache.object(forKey:tokenId)) {
    case .some(let image):
      return Promise.value(image)
    case .none:
      return firebase.getObject(path:self.path(tokenId))
        .then { (data:Data?) -> Promise<Media.IpfsImage?> in
          switch(data) {
          case .none:
            return onCacheMiss(tokenId)
          case .some(let data):
            return Promise.value(Media.IpfsImage.makeOpt(data))
          }
        }.map {
          $0.map { try? imageCache.setObject($0, forKey: tokenId) }
          return $0
        }
    }
  }
  
}
