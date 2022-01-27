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

func reduce_p<Element,Result>(_ items:Array<Element>,
                              _ initialResult: Result,
                              _ nextPartialResult: @escaping (Result, Element) -> Promise<Result>) -> Promise<Result> {
  
  return items.reduce(Promise.value(initialResult), { accu,item in
    accu
      .then { accu in
        nextPartialResult(accu,item)
          .recover { error -> Promise<Result> in
            print("Error in chain for item=\(item), Error=\(error)");
            return Promise.value(accu)
          }
      }
    
  })
}

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
  switch(collection.contract.getNFT(tokenId).media) {
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
  
  print("Fetching Favorite Sales")
  
  let favorites = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.favoritesDict.rawValue) as? [String : [String : Bool]]
  
  struct Order : Codable {
    let contract_address : String
    let token_id : UInt
    let wei : BigUInt
    let expiration_time : UInt?
  }
  
  
  let orders : Promise<[(Collection,[Order])]> = reduce_p(
    favorites?.map { ($0,$1) } ?? [],
    [],{ accu,item in
      let (address,tokens) = item
      return collectionsFactory.getByAddress(address).then { collection -> Promise<[(Collection,[Order])]> in
        
        let tokenIds = tokens.compactMap { (tokenId,isFav) -> UInt? in
          if (isFav) { return UInt(tokenId) }
          else { return nil }
        }
        
        if (!tokenIds.isEmpty) {
          
          switch(collection.contract.tradeActions) {
          case .none:
            return Promise.value(accu)
          case .some(let tradeActions):
            return after(seconds:0.3).then { // throttle
              tradeActions.getBidAsk(tokenIds,.ask)
                .map { (bidAsks:[(tokenId:UInt,bidAsk:BidAsk)]) -> (Collection,[Order]) in
                  (collection,
                   bidAsks.compactMap { (tokenId,bidAsk) -> Order? in
                    bidAsk.ask.map {
                      Order(contract_address: address, token_id: tokenId, wei: $0.wei,expiration_time: $0.expiration_time)
                    }
                  }
                  )
                }.map { accu + [$0] }
            }
          }
        } else {
          return Promise.value(accu)
        }
      }
    }
  )
  
  let salesCache = try! DiskStorage<String, Order>(
    config: DiskConfig(name: "FavoriteSellOrder.cache",expiry: .never),
    transformer: TransformerFactory.forCodable(ofType: Order.self))
  
  try? salesCache.removeExpiredObjects()
  
  return orders.then {
    reduce_p(
      $0,
      false, { accu,result -> Promise<Bool> in
        let (collection,orders) = result
        print(orders)
        
        let filtered =
        orders
          .compactMap { order -> Order? in
            
            let key = "\(order.contract_address):\(order.token_id)"
            
            if let entry = try? salesCache.object(forKey: key) {
              // Entry in cache, lets compare and clean if needed
              let entry_expiry = entry.expiration_time ?? 0
              
              if (entry_expiry != 0
                  && Date(timeIntervalSince1970: Double(entry_expiry)).timeIntervalSinceNow.sign == .minus) {
                try? salesCache.removeObject(forKey: key)
              }
              else if (entry.wei == order.wei) { return nil }
            }
            
            try! salesCache.setObject(
              order,
              forKey: key,
              expiry: order.expiration_time.map { .date(Date(timeIntervalSince1970:Double($0))) }
            )
            
            return order
          }
        
        return reduce_p(filtered, accu, { accu,order -> Promise<Bool> in
          
          return downloadImageToLocalDisk(collection: collection, tokenId: order.token_id)
            .map { imageUrl in
              let content = UNMutableNotificationContent()
              content.title = "Favorite for Sale"
              content.subtitle = "\(collection.info.name) #\(order.token_id)"
              let wei = order.wei
              content.body = "On sale for \(spot.map { "\(UsdString(wei: wei, rate: $0)) (\(EthString(wei: wei)))" } ?? EthString(wei: wei) )"
              // content.sound = UNNotificationSound.default
              
              print("ImageUrl=\(String(describing:imageUrl))")
              
              imageUrl.map {
                content.attachments = [try! UNNotificationAttachment(identifier: "\(collection.info.name) #\(order.token_id)", url: $0, options: .none)]
              }
              
              content.userInfo = [
                "sheetState": "nftTrade",
                "address" : collection.info.address,
                "tokenId" : order.token_id
              ]
              
              // show this notification five seconds from now
              let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
              
              let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
              
              // add our notification request
              UNUserNotificationCenter.current().add(request)
              return (accu || true)
            }
        })
      })
  }
}

func fetchOffers(_ spot:Double?) -> Promise<Bool> {
  
  print("Fetching Offers")
  let userWallet = UserWallet()
  
  guard let address = userWallet.walletAddress else {
    return Promise.value(false)
  }
  
  let userSettings = UserSettings()
  
  let orders = OpenSeaApi.getOrders(contract:nil,tokenIds:nil,user:.owner(address),side:OpenSeaApi.Side.buy)
  return orders
    .then { orders -> Promise<Bool> in
      
      // TODO : Better cache checks
      let offersCache = try! DiskStorage<String, OpenSeaApi.AssetOrder>(
        config: DiskConfig(name: "OwnerBuyOffers.cache",expiry: .never),
        transformer: TransformerFactory.forCodable(ofType: OpenSeaApi.AssetOrder.self))
      
      try? offersCache.removeExpiredObjects()
      
      return reduce_p(
        orders,
        false, { accu,order -> Promise<Bool> in
          
          let collectionAddress = try! EthereumAddress(hex:order.asset.asset_contract.address,eip55:false).hex(eip55:true)
          
          return collectionsFactory.getByAddress(collectionAddress)
            .then { collection -> Promise<(Collection,OpenSeaApi.AssetOrder)?> in
              
              let key = "\(order.asset.asset_contract.address):\(order.asset.token_id)"
              
              if let entry = try? offersCache.object(forKey: key) {
                // Entry in cache, lets compare and clean if needed
                if (entry.expiration_time != 0 && Date(timeIntervalSince1970: Double(entry.expiration_time)).timeIntervalSinceNow.sign == .minus) {
                  try? offersCache.removeObject(forKey: key)
                }
                else if (Double(entry.current_price)! >= Double(order.current_price)!) { return Promise.value(nil) }
                
              }
              
              return collection.contract.indicativeFloor()
                .map { floor -> (Collection,OpenSeaApi.AssetOrder)? in
                  // Check user settings limit
                  var withinLimit = false
                  switch(floor,userSettings.offerNotificationMinimum) {
                  case (.none,_):
                    withinLimit = true
                  case (.some,.None):
                    withinLimit = true
                  case (.some(let floor),.OTM_20_pct):
                    withinLimit = Double(order.current_price)! > (floor * 1e18 * 0.8)
                  case (.some(let floor),.OTM_10_pct):
                    withinLimit = Double(order.current_price)! > (floor * 1e18 * 0.9)
                  case (.some(let floor),.OTM_5_pct):
                    withinLimit = Double(order.current_price)! > (floor * 1e18 * 0.95)
                  case (.some(let floor),.ATM):
                    withinLimit = Double(order.current_price)! > (floor * 1e18 * 1.0)
                  case (.some(let floor),.ITM_5_pct):
                    withinLimit = Double(order.current_price)! > (floor * 1e18 * 1.05)
                  case (.some(let floor),.ITM_10_pct):
                    withinLimit = Double(order.current_price)! > (floor * 1e18 * 1.1)
                  case (.some(let floor),.ITM_20_pct):
                    withinLimit = Double(order.current_price)! > (floor * 1e18 * 1.2)
                  }
                  
                  if (withinLimit) {
                    
                    try! offersCache.setObject(
                      order,
                      forKey: key,
                      expiry: order.expiration_time != 0 ? .date(Date(timeIntervalSince1970:Double(order.expiration_time ))) : nil)
                    return (collection,order)
                  } else {
                    return nil
                  }
                }
            }
            .recover { error -> Promise<(Collection,OpenSeaApi.AssetOrder)?> in
              print("Error fetching order:\(error)");
              return Promise.value(nil)
            }
            .then { resultOpt -> Promise<Bool> in
              
              guard let result = resultOpt else {
                return Promise.value(accu)
              }
              
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
                  return accu || true
                }
            }
          
        })
    }
}


func performBackgroundFetch() -> Promise<Bool> {
  // Dispatch to multiple fetchers
  
  EthSpot.getLiveRate().then { spot in
    fetchOffers(spot)
      .recover { error -> Promise<Bool> in
        print("FetchOffers Failed with:\(error)")
        return Promise.value(false)
      }
      .then { foundOffers in
        fetchFavoriteSales(spot)
          .map { foundFavs in
            return foundOffers || foundFavs
          }
      }
  }
}
