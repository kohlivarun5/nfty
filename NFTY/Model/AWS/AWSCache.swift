//
//  AWSCache.swift
//  NFTY
//
//  Created by Varun Kohli on 4/15/22.
//

import Foundation
import UIKit
import Cache
import PromiseKit
import BigInt

struct AWSImageCache {
  
  struct Images {
    let sd : UIImage
    let hd : UIImage
  }
  
  let bucket : String
  
  private let awsClient = AWSClient()
  
  private var imageCache : DiskStorage<BigUInt,Media.IpfsImage>
  
  let fallback : (_ tokenId:BigUInt) -> Promise<Data?>
  
  private func onCacheMiss(_ tokenId:BigUInt) -> Promise<Media.IpfsImage?> {
    let ret = Task {
      return self.fallback(tokenId)
        .map { data -> Media.IpfsImage? in
          switch(data) {
          case .none:
            return nil
          case .some(let data):
            let _ = Task { await awsClient.putObject(bucket: self.bucket, key: String(tokenId), data) }
            return Media.IpfsImage.makeOpt(data)
          }
        }
    }
    return Promise { seal in
      let res = ret.value
      seal.fulfill(res)
    }
  }
  
  func image(_ tokenId:BigUInt) async -> Media.IpfsImage? {
    switch(try? self.imageCache.object(forKey:tokenId)) {
    case .some(let image):
      return image
    case .none:
      let data_opt = await awsClient.getObject(bucket:self.bucket, key:String(tokenId))
      switch(data_opt) {
      case .none:
        return onCacheMiss(tokenId)
      case .some(let ipfsImage)
      }
      let ipfsImage = Media.IpfsImage.makeOpt(data_opt)
      ipfsImage.map {
        try? imageCache.setObject($0, forKey:tokenId)
      }
      return ipfsImage
    }
  }
  
}
