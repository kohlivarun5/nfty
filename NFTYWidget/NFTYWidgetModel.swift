//
//  NFTYWidgetModel.swift
//  NFTYWidgetExtension
//
//  Created by Varun Kohli on 1/18/22.
//

import Foundation
import WidgetKit
import Intents
import Cache


struct CollectionStats {
  let info : CollectionFloorData
  let percent_change : Double?
  let since : Date?
}

struct Provider: IntentTimelineProvider {
  
  struct FloorPrice : Codable {
    let floorPrice : Double
    let date : Date
  }
  
  struct FloorPrices : Codable {
    let prev : FloorPrice
    let latest : FloorPrice
  }
  
  private var lastPriceCache = try! DiskStorage<String, FloorPrices>(
    config: DiskConfig(name: "Provider.FloorPrices",expiry: .never),
    transformer:TransformerFactory.forCodable(ofType:FloorPrices.self))
  
  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(
      date: Date(),
      configuration: ConfigurationIntent(),
      collections:Array(0...100).map {
        CollectionStats(
          info:CollectionFloorData(
            id: "\($0)",
            name: $0.isMultiple(of: 2) ? "CryptoMories" : "Illuminati",
            floorPrice: 1.409),
          percent_change: $0.isMultiple(of: 2) ? 0.5213123 : -0.23,
          since:Date())
      }
    )
    
  }
  
  func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
    print("getSnapshot")
    completion(placeholder(in:context))
  }
  
  func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
    print("getTimeline")
    
    fetchStats()
      .done { collections in
        
        let date = Date()
        let entries = [
          SimpleEntry(
            date: date,
            configuration: configuration,
            collections:
              collections
              .map { info in
                
                var since : Date? = nil
                var change : Double? = nil
                
                // The cache is setup to keep 2 value, because if we just keep one,
                // we see all unch when the time lapses
                switch(try? lastPriceCache.object(forKey:info.id)) {
                case .some(let prices):
                  // find change by comparing the present and prev timelines
                  if (date.timeIntervalSince(prices.latest.date) >= (60 * 60 * 6)) {
                    change = prices.latest.floorPrice == info.floorPrice ? nil : (info.floorPrice - prices.latest.floorPrice) / prices.latest.floorPrice
                    since = prices.latest.date
                    
                    // present is greater than 6 hours, make it prev
                    try? lastPriceCache.setObject(
                      FloorPrices(
                        prev:prices.latest,
                        latest:FloorPrice(floorPrice:info.floorPrice,date:date)
                      ),forKey:info.id)
                    
                  } else {
                    change = prices.prev.floorPrice == info.floorPrice ? nil : (info.floorPrice - prices.prev.floorPrice) / prices.prev.floorPrice
                    since = prices.prev.date
                  }
                  
                case .none:
                  try? lastPriceCache.setObject(
                    FloorPrices(
                      prev:FloorPrice(floorPrice:info.floorPrice,date:date),
                      latest:FloorPrice(floorPrice:info.floorPrice,date:date)
                    ),forKey:info.id)
                }
                
                let stats = CollectionStats(info: info,percent_change:change,since:since)
                
                print(stats)
                return stats
              }
          )
        ]
        
        let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: entries, policy: .after(refresh))
        completion(timeline)
      }
      .catch { print($0) }
    
    
  }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
  let configuration: ConfigurationIntent
  let collections : [CollectionStats]
}


struct Formatters {
  static var eth : Formatter = {
    let currencyFormatter = NumberFormatter()
    currencyFormatter.usesGroupingSeparator = true
    currencyFormatter.numberStyle = .currency
    // localize to your grouping and decimal separator
    currencyFormatter.locale = Locale.current
    currencyFormatter.maximumFractionDigits = 3
    currencyFormatter.currencySymbol = "Ξ"
    return currencyFormatter
  }()
  
  static var percentage : Formatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    formatter.positivePrefix = "▲ "
    formatter.negativePrefix = "▼ "
    formatter.minimumFractionDigits = 1
    formatter.maximumFractionDigits = 1
    return formatter
  }()
}
