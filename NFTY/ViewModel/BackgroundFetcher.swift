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

extension Promise {
  
  /**
   * Create a final Promise that chain all delayed promise callback all together.
   */
  static func chain(_ promises:[() -> Promise<T>]) -> Promise<[T]> {
    return Promise<[T]> { seal in
      var out = [T]()
      
      let fp:Promise<T>? = promises.reduce(nil) { (r, o) in
        return r?.then { c -> Promise<T> in
          out.append(c)
          return o()
        } ?? o()
      }
      
      fp?.map { c -> Void in
        out.append(c)
        seal.fulfill(out)
      }
      .catch(seal.reject)
    }
  }
}

import Cache

func fetchFavoriteSales() -> Promise<Bool> {
  let favorites = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.favoritesDict.rawValue) as? [String : [String : Bool]]
  
  var orders : [() -> Promise<(Collection,[OpenSeaApi.AssetOrder])>] = []
  
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
        orders.append({
          OpenSeaApi.getOrders(contract:address,tokenIds:tokenIds,user:nil,side:OpenSeaApi.Side.sell)
            .map { (collection,$0) }
        })
      }
    }
  }
  
  return Promise.chain(orders)
    .then { results in
      return EthSpot.getLiveRate().map { ($0,results) }
    }
    .map { (spot,results) in
      
      var salesCache = try! DiskStorage<String, OpenSeaApi.AssetOrder>(
        config: DiskConfig(name: "FavSales.cache",expiry: .never),
        transformer: TransformerFactory.forCodable(ofType: OpenSeaApi.AssetOrder.self))
      
      // called when 'promises.last' is invoked and fulfilled.
      // Remember last time we ran
      // If we don't know last time, skip notifying, rather than over notifying
      // Check new offers
      // Check expiring offers, even if not new
      results
        .forEach {
          let (collection,orders) = $0
          print(orders)
          orders
            .compactMap { $0 }
            .forEach { order in
              
              let key = "\(order.asset.asset_contract.address):\(order.asset.token_id)"
              
              switch(try? salesCache.object(forKey: key)) {
              case .some:
                break
              case .none:
                
                try! salesCache.setObject(order, forKey: key)
                
                let content = UNMutableNotificationContent()
                content.title = "Favorite for Sale"
                content.subtitle = "\(collection.info.name) #\(order.asset.token_id)"
                content.body = "On sale for \(spot.map { UsdString(wei: BigUInt(order.current_price)!, rate: $0) } ?? EthString(wei: BigUInt(order.current_price)!) )"
                // content.sound = UNNotificationSound.default
                
                // show this notification five seconds from now
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                
                // choose a random identifier
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                
                // add our notification request
                UNUserNotificationCenter.current().add(request)
              }
            }
        }
      
      return !orders.isEmpty
    }
}

func performBackgroundFetch() -> Promise<Bool> {
  // Dispatch to multiple fetchers
  return fetchFavoriteSales()
}
