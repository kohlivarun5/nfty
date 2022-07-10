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

#if os(macOS)
import AppKit
#else
import UIKit
#endif



struct CKImageCacheCore {
  
  enum CompressionAlgorithm : Int {
    case lzfse
  }
  
  private func compressedData(data:Data,compressionAlgorithm:CompressionAlgorithm) -> (NSData,CompressionAlgorithm?) {
    switch(compressionAlgorithm) {
    case .lzfse:
      switch(try? (data as NSData).compressed(using: .lzfse)) {
      case .some(let compressed):
        return (compressed,compressionAlgorithm)
      case .none:
        return ((data as NSData),nil)
      }
    }
  }
  
  private func createLocalFile(path:String,data: Data,compressionAlgorithm:CompressionAlgorithm) -> (URL,CompressionAlgorithm?) {
    let (data,compressionAlgorithm) = compressedData(data:data,compressionAlgorithm: compressionAlgorithm)
    let tmpSubFolderURL = URL(fileURLWithPath: NSTemporaryDirectory())
    let fileURL = tmpSubFolderURL.appendingPathComponent(path.replacingOccurrences(of: "/", with: "."))
    try! data.write(to: fileURL)
    return (fileURL,compressionAlgorithm)
  }
  
  private func readLocalFile(_ url:URL,compressionAlgorithm:CompressionAlgorithm?) -> Data? {
    guard let algorithm = compressionAlgorithm else { return try? Data(contentsOf:url) }
    switch(algorithm) {
    case .lzfse:
      return try? NSData(contentsOf:url).decompressed(using: .lzfse) as Data
    }
  }
  
  let database : CKDatabase
  let bucket : String
  let fallback : (_ tokenId:BigUInt) -> Promise<Data?>
  let collectionAddress : String
  
#if os(macOS)
  private var imageCache : DiskStorage<BigUInt,NSImage>
  private var imageCacheHD : DiskStorage<BigUInt,NSImage>
#else
  private var imageCache : DiskStorage<BigUInt,UIImage>
  private var imageCacheHD : DiskStorage<BigUInt,UIImage>
#endif
  
  private let assetKey = "image"
  private let compressionAlgorithmKey = "compressionAlgorithm"
  private let neuralHashKey = "neuralHash"
  private let collectionAddressKey = "collectionAddress"
  
  
  init(database:CKDatabase,bucket:String,collectionAddress:String,fallback:@escaping (_ tokenId:BigUInt) -> Promise<Data?>) {
    self.database = database
    self.bucket = bucket
    self.fallback = fallback
    self.collectionAddress = collectionAddress
    
#if os(macOS)
    self.imageCache = try! DiskStorage<BigUInt, NSImage>(
      config: DiskConfig(name: "\(bucket).ImageCacheSD",expiry: .never),
      transformer: TransformerFactory.forImage())
    self.imageCacheHD = try! DiskStorage<BigUInt, NSImage>(
      config: DiskConfig(name: "\(bucket).ImageCacheHD",expiry: .never),
      transformer: TransformerFactory.forImage())
#else
    self.imageCache = try! DiskStorage<BigUInt, UIImage>(
      config: DiskConfig(name: "\(bucket).ImageCacheSD",expiry: .never),
      transformer: TransformerFactory.forImage())
    self.imageCacheHD = try! DiskStorage<BigUInt, UIImage>(
      config: DiskConfig(name: "\(bucket).ImageCacheHD",expiry: .never),
      transformer: TransformerFactory.forImage())
#endif
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
          let compressionAlgorithm = CompressionAlgorithm.lzfse
          NeuralHash.generate(image: data) { (neuralHash:String?) in
            let (file,compressionAlgorithm) = createLocalFile(path:recordId,data:data,compressionAlgorithm: compressionAlgorithm)
            record.setValuesForKeys([
              collectionAddressKey : self.collectionAddress,
              assetKey: CKAsset.init(fileURL: file)
            ])
            if let compressionAlgorithm = compressionAlgorithm {
              record.setValue(compressionAlgorithm.rawValue, forKey: compressionAlgorithmKey)
            }
            if let neuralHash = neuralHash {
              print("NeuralHash=\(neuralHash) for \(recordId)")
              record.setValue(neuralHash, forKey: neuralHashKey)
            }
            print("Saving recordId=\(recordId)")
            database.save(record:record)
              .done(on:.global(qos: .background)) { result in
                print("Save returned for \(recordId)")
              }
              .catch { print($0) }
          }
        }
        return image
      }
  }
  
  /*
   TokenImageCache
   collectionAddress
   STRING
   Queryable
   
   compressionAlgorithm
   INT(64)
   None
   
   image
   ASSET
   None
   
   neuralHash
   STRING
   Sortable
   

   */
  
  
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
              let (record,_) = result
              // print("Fetch returned with error=\(String(describing: error))")
              
              let fileUrl = (record?[assetKey] as? CKAsset)?.fileURL
              let compressionAlgorithm = (record?[compressionAlgorithmKey] as? Int).flatMap { CompressionAlgorithm(rawValue: $0) }
              
              switch(fileUrl.flatMap { readLocalFile($0,compressionAlgorithm: compressionAlgorithm) }) {
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
