//
//  CKImageCache.swift
//  NFTY
//
//  Created by Varun Kohli on 6/7/22.
//

import Foundation
import CloudKit
import BigInt
import PromiseKit
import Cache
import UIKit

struct CKImageCacheCore {
  
  
  private func createLocalFile(path:String,data: Data) -> URL {
    let tmpSubFolderURL = URL(fileURLWithPath: NSTemporaryDirectory())
    let fileURL = tmpSubFolderURL.appendingPathComponent(path.replacingOccurrences(of: "/", with: "."))
    try! data.write(to: fileURL)
    return fileURL
    
  }
  
  let database : CKDatabase
  let bucket : String
  let fallback : (_ tokenId:BigUInt) -> Promise<Data?>
  
  private var imageCache : DiskStorage<BigUInt,UIImage>
  private var imageCacheHD : DiskStorage<BigUInt,UIImage>
  
  private let assetKey = "image"
  
  init(database:CKDatabase,bucket:String,fallback:@escaping (_ tokenId:BigUInt) -> Promise<Data?>) {
    self.database = database
    self.bucket = bucket
    self.fallback = fallback
    self.imageCache = try! DiskStorage<BigUInt, UIImage>(
      config: DiskConfig(name: "\(bucket).ImageCacheSD",expiry: .never),
      transformer: TransformerFactory.forImage())
    self.imageCacheHD = try! DiskStorage<BigUInt, UIImage>(
      config: DiskConfig(name: "\(bucket).ImageCacheHD",expiry: .never),
      transformer: TransformerFactory.forImage())
  }
  
  
  private func recordName(_ tokenId:BigUInt) -> String {
    return "\(bucket)/\(tokenId)"
  }
  
  private func imageOfData(_ data:Data) -> Media.IpfsImage? {
    return UIImage(data:data)
      .flatMap { image_hd in
        image_hd
          .jpegData(compressionQuality: 0.1)
          .flatMap { UIImage(data:$0) }
          .map { Media.IpfsImage(image:$0,image_hd:image_hd) }
      }
  }
  
  private func onCacheMiss(_ tokenId:BigUInt) -> Promise<Media.IpfsImage?> {
    return self.fallback(tokenId)
      .map(on:DispatchQueue.global(qos:.userInteractive)) { data -> Media.IpfsImage? in
        guard let data = data else { return nil }
        guard let image = imageOfData(data) else { return nil }
        
        DispatchQueue.global(qos:.background).async {
          let recordId = self.recordName(tokenId)
          let record = CKRecord.init(recordType: "TokenImageCache", recordID:CKRecord.ID.init(recordName:recordId))
          record.setValuesForKeys([assetKey: CKAsset.init(fileURL: createLocalFile(path:recordId,data:data))])
          print("Saving recordId=\(recordId)")
          database.save(record:record)
            .done(on:.global(qos: .background)) { result in
              print("Save returned for \(recordId)")
            }
            .catch { print($0) }
        }
        return image
      }
  }
  
  
  func image(_ tokenId:BigUInt) -> ObservablePromise<Media.IpfsImage?> {
    return ObservablePromise(promise: Promise { seal in
      DispatchQueue.global(qos:.userInteractive).async {
        switch(try? self.imageCache.object(forKey:tokenId),try? self.imageCacheHD.object(forKey:tokenId)) {
        case (.some(let image),.some(let image_hd)):
          seal.fulfill(Media.IpfsImage(image: image,image_hd: image_hd))
         case (.none,_),(_,.none):
          let recordName = self.recordName(tokenId)
          print("Fetching for record=\(recordName)")
          database.fetchRecordWithID(recordID:CKRecord.ID.init(recordName:recordName))
            .then(on:DispatchQueue.global(qos:.userInteractive)) { result -> Promise<Media.IpfsImage?> in
              let (record,error) = result
              print("Fetch returned with error=\(String(describing: error))")
              
              switch((record?[assetKey] as? CKAsset)?.fileURL.flatMap { try? Data(contentsOf:$0) }) {
              case .none:
                // print("Record \(recordName) did not return asset")
                return onCacheMiss(tokenId)
              case .some(let data):
                return Promise.value(imageOfData(data))
              }
            }.done(on:DispatchQueue.global(qos:.userInteractive)) { image in
              DispatchQueue.global(qos:.background).async {
                image.map {
                  try? self.imageCache.setObject($0.image, forKey: tokenId)
                  try? self.imageCacheHD.setObject($0.image_hd, forKey: tokenId)
                }
              }
              seal.fulfill(image)
            }
            .catch { print($0) }
        }
      }
    })
  }
}
