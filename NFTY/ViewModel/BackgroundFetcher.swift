//
//  BackgroundFetcher.swift
//  NFTY
//
//  Created by Varun Kohli on 10/4/21.
//

import Foundation
import PromiseKit
import UserNotifications
import BigInt
import Web3
import Cache
import UIKit

func createLocalFile(folder:String,collection:Collection,tokenId:UInt,image: UIImage) -> URL? {
  let fileManager = FileManager.default
  let tmpSubFolderURL = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent(folder, isDirectory: true)
    .appendingPathComponent(collection.info.address, isDirectory: true)
  do {
    try fileManager.createDirectory(at: tmpSubFolderURL, withIntermediateDirectories: true, attributes: nil)
    let imageFileIdentifier = String(tokenId)+".png"
    let fileURL = tmpSubFolderURL.appendingPathComponent(imageFileIdentifier)
    let imageData = UIImage.pngData(image)
    try imageData()?.write(to: fileURL)
    return fileURL
  } catch {
    print("error " + error.localizedDescription)
  }
  return nil
}

func downloadImageToLocalDisk(collection:Collection,tokenId:UInt) -> Promise<URL?> {
  let notificationImagesFolder = "NotificationImages"
  switch(collection.data.contract.getNFT(tokenId).media) {
  case .ipfsImage(let image):
    return image.image.promise.map { uiImage in
      uiImage.flatMap {
        createLocalFile(folder: notificationImagesFolder, collection: collection, tokenId: tokenId, image: $0.image)
      }
    }
  case .image,.asciiPunk,.autoglyph:
    return Promise.value(nil)
    
  }
}

func fetchFavoriteSales(_ spot : Double?) -> Promise<Bool> {
  let favorites = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.favoritesDict.rawValue) as? [String : [String : Bool]]
  
  var orders : [Promise<(Collection,[OpenSeaApi.AssetOrder])>] = []
  
  favorites?.forEach { (address,tokens) in
    collectionsFactory.getByAddress(address).map { collection in
      let tokenIds = tokens.compactMap { (tokenId,isFav) -> UInt? in
        if (isFav) {
          return UInt(tokenId)
        } else {
          return nil
        }
      }
      
      if (!tokenIds.isEmpty) {
        orders.append(contentsOf:
          tokenIds.map {
            OpenSeaApi.getAssetBidAsk(contract: address, tokenId:$0)
            .map { (collection,$0.filter { $0.side == .sell }) }
          }
        )
      }
    }
  }
  
  let salesCache = try! DiskStorage<String, OpenSeaApi.AssetOrder>(
    config: DiskConfig(name: "FavoriteSales.cache",expiry: .never),
    transformer: TransformerFactory.forCodable(ofType: OpenSeaApi.AssetOrder.self))
  
  try? salesCache.removeExpiredObjects()
  
  return when(fulfilled:orders)
    .then { results -> Promise<Bool> in
      let promises = results
        .map { result -> Promise<Bool> in
          let (collection,orders) = result
          print(orders)
          let promises = orders
            .compactMap { (order:OpenSeaApi.AssetOrder) -> OpenSeaApi.AssetOrder? in
              
              let key = "\(order.asset.asset_contract.address):\(order.asset.token_id)"
              
              if let entry = try? salesCache.object(forKey: key) {
                // Entry in cache, lets compare and clean if needed
                if (entry.expiration_time != 0 && Date(timeIntervalSince1970: Double(entry.expiration_time)).timeIntervalSinceNow.sign == .minus) {
                  try? salesCache.removeObject(forKey: key)
                }
                else if (entry.current_price == order.current_price) { return nil }
              }
              
              try! salesCache.setObject(
                order,
                forKey: key,
                expiry: order.expiration_time != 0 ? .date(Date(timeIntervalSince1970:Double(order.expiration_time ))) : nil)
              
              return order
            }
            .map { order -> Promise<Void> in
              
              return downloadImageToLocalDisk(collection: collection, tokenId: UInt(order.asset.token_id)!)
                .map { imageUrl in
                  let content = UNMutableNotificationContent()
                  content.title = "Favorite for Sale"
                  content.subtitle = "\(collection.info.name) #\(order.asset.token_id)"
                  let wei = Double(order.current_price).map { BigUInt($0) }
                  content.body = "On sale for \(spot.map { "\(UsdString(wei: wei!, rate: $0)) (\(EthString(wei: wei!)))" } ?? EthString(wei: wei!) )"
                  // content.sound = UNNotificationSound.default
                  
                  print("ImageUrl=\(String(describing:imageUrl))")
                  
                  imageUrl.map {
                    content.attachments = [try! UNNotificationAttachment(identifier: "\(collection.info.name) #\(order.asset.token_id)", url: $0, options: .none)]
                  }
                  
                  content.userInfo = [
                    "sheetState": "nftTrade",
                    "address" : collection.info.address,
                    "tokenId" : UInt(order.asset.token_id)!
                  ]
                  
                  // show this notification five seconds from now
                  let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                  
                  let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                  
                  // add our notification request
                  UNUserNotificationCenter.current().add(request)
                }
            }
          
          return when(fulfilled: promises).map { !$0.isEmpty }
        }
      
      return when(fulfilled: promises).map { $0.allSatisfy({$0}) }
    }
}

func fetchOffers(_ spot:Double?) -> Promise<Bool> {
  
  let userWallet = UserWallet()
  
  guard let address = userWallet.walletAddress else {
    return Promise.value(false)
  }
  
  let orders = OpenSeaApi.getOrders(contract:nil,tokenIds:nil,user:.owner(address),side:OpenSeaApi.Side.buy)
  return orders
    .then { orders -> Promise<Bool> in
      
      // TODO : Better cache checks
      let offersCache = try! DiskStorage<String, OpenSeaApi.AssetOrder>(
        config: DiskConfig(name: "OwnerBuyOffers.cache",expiry: .never),
        transformer: TransformerFactory.forCodable(ofType: OpenSeaApi.AssetOrder.self))
      
      try? offersCache.removeExpiredObjects()
      
      let promises = orders
        .compactMap { order -> (Collection,OpenSeaApi.AssetOrder)? in
          
          let collectionAddress = try! EthereumAddress(hex:order.asset.asset_contract.address,eip55:false).hex(eip55:true)
          
          guard let collection = collectionsFactory.getByAddress(collectionAddress) else {
            print("Collection \(collectionAddress) not supported")
            return nil
          }
          
          let key = "\(order.asset.asset_contract.address):\(order.asset.token_id)"
          
          if let entry = try? offersCache.object(forKey: key) {
            // Entry in cache, lets compare and clean if needed
            if (entry.expiration_time != 0 && Date(timeIntervalSince1970: Double(entry.expiration_time)).timeIntervalSinceNow.sign == .minus) {
              try? offersCache.removeObject(forKey: key)
            }
            else if (Double(entry.current_price)! >= Double(order.current_price)!) { return nil }
            
          }
          
          try! offersCache.setObject(
            order,
            forKey: key,
            expiry: order.expiration_time != 0 ? .date(Date(timeIntervalSince1970:Double(order.expiration_time ))) : nil)
          return (collection,order)
          
        }.map { result -> Promise<Void> in
          let (collection,order) = result
          return downloadImageToLocalDisk(collection: collection, tokenId: UInt(order.asset.token_id)!)
            .map { imageUrl in
              
              let content = UNMutableNotificationContent()
              content.title = "New Offer"
              //content.subtitle = "\(collection.info.name) #\(order.asset.token_id)"
              print(order)
              
              // TODO : Handle currency tokens
              let wei = Double(order.current_price).map { BigUInt($0) }
              content.subtitle = "\(collection.info.name) #\(order.asset.token_id)"
              content.body = "Offer: \(spot.map { "\(UsdString(wei: wei!, rate: $0)) (\(EthString(wei: wei!)))" } ?? EthString(wei: wei!) )"
              
              print("ImageUrl=\(String(describing:imageUrl))")
              
              imageUrl.map {
                content.attachments = [try! UNNotificationAttachment(identifier: "\(collection.info.name) #\(order.asset.token_id)", url: $0, options: .none)]
              }
              
              content.userInfo = [
                "sheetState": "nftTrade",
                "address" : collection.info.address,
                "tokenId" : UInt(order.asset.token_id)!
              ]
              
              // show this notification five seconds from now
              let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
              
              // choose a random identifier
              let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
              
              // add our notification request
              UNUserNotificationCenter.current().add(request)
            }
        }
      
      return when(fulfilled: promises).map { !$0.isEmpty }
    }
}


func performBackgroundFetch() -> Promise<Bool> {
  // Dispatch to multiple fetchers
  
  EthSpot.getLiveRate().then { spot in
        fetchFavoriteSales(spot)
    /*
    fetchOffers(spot)
      .then { foundOffers in
        fetchFavoriteSales(spot)
          .map { foundFavs in
            return foundOffers || foundFavs
          }
      }
     */
  }
}
