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

func createLocalFile(folder:String,collection:Collection,tokenId:BigUInt,image: UIImage) -> URL? {
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

func downloadImageToLocalDisk(collection:Collection,tokenId:BigUInt) -> Promise<URL?> {
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
    let token_id : BigUInt
    let price : PriceUnit
    let expiration_time : UInt?
  }
  
  
  let orders : Promise<[(Collection,[Order])]> = reduce_p(
    favorites?.map { ($0,$1) } ?? [],
    [],{ accu,item in
      let (address,tokens) = item
      return collectionsFactory.getByAddress(address).then { collection -> Promise<[(Collection,[Order])]> in
        
        let tokenIds = tokens.compactMap { (tokenId,isFav) -> BigUInt? in
          if (isFav) { return BigUInt(tokenId) }
          else { return nil }
        }
        
        if (!tokenIds.isEmpty) {
          
          switch(collection.contract.tradeActions) {
          case .none:
            return Promise.value(accu)
          case .some(let tradeActions):
            return after(seconds:0.3).then { // throttle
              tradeActions.getBidAsk(tokenIds,.ask)
                .map { (bidAsks:[(tokenId:BigUInt,bidAsk:BidAsk)]) -> (Collection,[Order]) in
                  (collection,
                   bidAsks.compactMap { (tokenId,bidAsk) -> Order? in
                    bidAsk.ask.map {
                      Order(contract_address: address, token_id: tokenId, price: $0.price,expiration_time: $0.expiration_time)
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
        // print(orders)
        
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
              else if (entry.price == order.price) { return nil }
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
              
              switch(order.price) {
              case .wei(let wei):
                content.body = "On sale for \(spot.map { "\(UsdString(wei: wei, rate: $0)) (\(EthString(wei: wei)))" } ?? EthString(wei: wei) )"
              case .near(let near):
                content.body = "On sale for \(PriceString(price:.near(near)) )"
              }
              print("ImageUrl=\(String(describing:imageUrl))")
              
              imageUrl.flatMap {
                try? UNNotificationAttachment(identifier: "\(collection.info.name) #\(order.token_id)", url: $0, options: .none)
              }.map {
                content.attachments = [$0]
              }
              
              content.userInfo = [
                "sheetState": "nftTrade",
                "address" : collection.info.address,
                "tokenId" : String(order.token_id) // Needs to be string as BigUInt doesn't conform to secure encoding https://github.com/kohlivarun5/nfty/pull/320
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
  
  guard let address = userWallet.walletEthAddress else {
    return Promise.value(false)
  }
  
  let userSettings = UserSettings()
  
  // TODO Support Near
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
          
          guard let collectionAddress = try? EthereumAddress(hex:order.asset.asset_contract.address,eip55:false).hex(eip55:true) else { return Promise.value(accu) }
          
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
                  switch(floor,Double(order.current_price).map { BigUInt($0) },userSettings.offerNotificationMinimum) {
                  case (.none,_,_),(_,.none,_):
                    withinLimit = true
                  case (.some,.some,.None):
                    withinLimit = true
                  case (.some(let floor),.some(let current_price),.OTM_20_pct):
                    withinLimit = PriceUnit.change(
                      new: .wei(current_price),
                      prev: floor)! > (-0.2)
                  case (.some(let floor),.some(let current_price),.OTM_10_pct):
                    withinLimit = PriceUnit.change(
                      new: .wei(current_price),
                      prev: floor)! > (-0.1)
                  case (.some(let floor),.some(let current_price),.OTM_5_pct):
                    withinLimit = PriceUnit.change(
                      new: .wei(current_price),
                      prev: floor)! > (-0.05)
                  case (.some(let floor),.some(let current_price),.ATM):
                    withinLimit = PriceUnit.change(
                      new: .wei(current_price),
                      prev: floor)! > 0
                  case (.some(let floor),.some(let current_price),.ITM_5_pct):
                    withinLimit = PriceUnit.change(
                      new: .wei(current_price),
                      prev: floor)! > 0.05
                  case (.some(let floor),.some(let current_price),.ITM_10_pct):
                    withinLimit = PriceUnit.change(
                      new: .wei(current_price),
                      prev: floor)! > 0.1
                  case (.some(let floor),.some(let current_price),.ITM_20_pct):
                    withinLimit = PriceUnit.change(
                      new: .wei(current_price),
                      prev: floor)! > 0.2
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
              
              guard let tokenId = BigUInt(order.asset.token_id) else { return Promise.value(accu) }
              
              return downloadImageToLocalDisk(collection: collection, tokenId:tokenId)
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
                  
                  guard let tokenId = try? String(order.asset.token_id) else { return accu }
                  content.userInfo = [
                    "sheetState": "nftTrade",
                    "address" : collection.info.address,
                    "tokenId" : tokenId
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

func loadFeed() -> Promise<Bool> {
  
  let friendDict = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.friendsDict.rawValue) as? [String : String] ?? [:]
  
  let friends = friendDict.keys.compactMap { try? EthereumAddress(hex: $0, eip55: true) }
  print("Loading feed for \(friends.map { $0.hex(eip55:true) })")
  let feed = FriendsFeedViewModel(from: friends,limit:20)
  
  return Promise { seal in
    feed.getRecentEvents(currentIndex: 0, {
      reduce_p(feed.recentEvents,(),{ (accu,event) in
        return Promise { seal in
          
          switch(event.nft.nftWithPrice.nft.media) {
          case .ipfsImage(let image):
            image.image.loadMore { seal.fulfill(()) }
          case .image(let image):
            image.url.loadMore { seal.fulfill(()) }
          case .asciiPunk,.autoglyph:
            seal.fulfill(())
          }
        }
      })
      .done { seal.fulfill(true) }
      .catch {
        print($0)
        seal.fulfill(false)
      }
    })
  }
}

func loadRecentsFeed() -> Promise<Bool> {
  
  return Promise { seal in
    CompositeCollection.loadLatest {
      reduce_p(CompositeCollection.recentTrades,(),{ (accu,event) in
        return Promise { seal in
          switch(event.nft.nftWithPrice.nft.media) {
          case .ipfsImage(let image):
            image.image.loadMore { seal.fulfill(()) }
          case .image(let image):
            image.url.loadMore { seal.fulfill(()) }
          case .asciiPunk,.autoglyph:
            seal.fulfill(())
          }
        }
      })
      .done { seal.fulfill(true) }
      .catch {
        print($0)
        seal.fulfill(false)
      }
    }
  }
}

func performBackgroundFetch() -> Promise<Bool> {
  // Dispatch to multiple fetchers
  
  return loadFeed()
    .recover { error -> Promise<Bool> in
      print("LoadFeed Failed with:\(error)")
      return Promise.value(false)
    }
    .then { loadedFeed -> Promise<Bool> in
      loadRecentsFeed()
        .recover { error -> Promise<Bool> in
          print("LoadRecents Failed with:\(error)")
          return Promise.value(false)
        }
        .map { loadedRecents -> Bool in
          return loadedFeed || loadedRecents
        }
    }.then { loadedFeed -> Promise<Bool> in
      
      return UserEthRate.getLiveRate().then { spot in
        fetchOffers(spot)
          .recover { error -> Promise<Bool> in
            print("FetchOffers Failed with:\(error)")
            return Promise.value(false)
          }
          .then { foundOffers in
            fetchFavoriteSales(spot)
              .recover { error -> Promise<Bool> in
                print("FetchFavorites Failed with:\(error)")
                return Promise.value(false)
              }
              .map { foundFavs in
                return loadedFeed || foundOffers || foundFavs
              }
          }
      }
    }
}
