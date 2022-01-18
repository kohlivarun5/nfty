//
//  NFTYWidget.swift
//  NFTYWidget
//
//  Created by Varun Kohli on 1/11/22.
//

import WidgetKit
import SwiftUI
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

struct NFTYWidgetEntryStackView : View {
  let collections: Array<CollectionStats>.SubSequence
  
  var body: some View {
    ForEach(
      collections,
      id:\.info.id
    ) { stats in
      VStack {
        HStack {
          Text(stats.info.name)
            .bold()
        }
        .colorMultiply(.accentColor)
        .font(.subheadline)
        
        HStack(spacing:0) {
          Text(Formatters.eth.string(for:stats.info.floorPrice)!)
            .bold()
            .frame(alignment: .leading)
          Spacer()
          
          switch(stats.percent_change) {
          case .none:
            Text("unch")
              .foregroundColor(.secondary)
              .frame(alignment: .trailing)
          case .some(let percentage):
            
            Text(Formatters.percentage.string(for: percentage)!)
              .foregroundColor(percentage < 0 ? Color.red : Color.green)
              .frame(alignment: .trailing)
          }
        }.font(.footnote)
      }
    }
  }
}


struct NFTYWidgetEntryView : View {
  var entry: Provider.Entry
  
  @Environment(\.widgetFamily) var widgetFamily
  
  var body: some View {
    VStack(spacing:8) {
      
      if (entry.collections.isEmpty) {
        Text("No Collections in Wallet")
          .multilineTextAlignment(.center)
          .foregroundColor(.secondary)
      } else {
        
        let sorted = entry.collections
          .sorted { $0.info.floorPrice > $1.info.floorPrice };
        
        switch(widgetFamily) {
        case .systemSmall:
          NFTYWidgetEntryStackView(collections:sorted.prefix(3))
        case .systemMedium:
          LazyVGrid(
            columns: Array(
              repeating:GridItem(.flexible(maximum:140),spacing:20),
              count:2
            ),spacing:8
          ) {
            NFTYWidgetEntryStackView(collections:sorted.prefix(6))
          }
        case .systemLarge:
          LazyVGrid(
            columns: Array(
              repeating:GridItem(.flexible(maximum:140),spacing:20),
              count:2
            ),spacing:8
          ) {
            NFTYWidgetEntryStackView(collections:sorted.prefix(12))
          }
          
        case .systemExtraLarge:
          LazyVGrid(
            columns: Array(
              repeating:GridItem(.flexible(maximum:140),spacing:20),
              count:4
            ),spacing:8
          ) {
            NFTYWidgetEntryStackView(collections:sorted.prefix(24))
          }
        }
        
        VStack(spacing:0) {
          sorted.compactMap { $0.since }.first.map { since in
            HStack {
              Text("Change since \(since.timeAgoDisplay())")
                .font(.system(size:7))
                .foregroundColor(Color.secondaryLabel)
              Spacer()
            }
          }
          
          (Text("Updated ") + Text(entry.date, style: .relative) + Text(" ago"))
            .font(.system(size:7))
            .foregroundColor(Color.secondaryLabel)
          
        }
        
      }
    }
    .padding([.leading,.trailing])
    .padding(.top,10)
    .padding(.bottom,7)
  }
}

@main
struct NFTYWidget: Widget {
  let kind: String = "NFTY"
  
  var body: some WidgetConfiguration {
    IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
      NFTYWidgetEntryView(entry: entry)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .environment(\.colorScheme,.dark)
        .accentColor(Color.orange)
    }
    .configurationDisplayName("Collections Floor")
    .description("Floor price updates for collections in wallet")
    .supportedFamilies([.systemSmall,.systemMedium,.systemLarge,.systemExtraLarge])
  }
}

struct NFTYWidget_Previews: PreviewProvider {
  
  static var previews: some View {
    
    let collections : [CollectionStats] = {
      return Array(0...100)
        .map {
          CollectionStats(
            info:CollectionFloorData(id: "\($0)", name: "CryptoMories\($0)", floorPrice: 1.409),
            percent_change:$0.isMultiple(of: 2) ? 0.5213123 : -0.23,
            since:Date())
        }
    }()
    
    Group {
      NFTYWidgetEntryView(
        entry: SimpleEntry(
          date: Date(),
          configuration: ConfigurationIntent(),collections:collections
        )
      ).previewContext(WidgetPreviewContext(family: .systemSmall))
      
      NFTYWidgetEntryView(
        entry: SimpleEntry(
          date: Date(),
          configuration: ConfigurationIntent(),collections:collections
        )
      ).previewContext(WidgetPreviewContext(family: .systemMedium))
      
      NFTYWidgetEntryView(
        entry: SimpleEntry(
          date: Date(),
          configuration: ConfigurationIntent(),collections:collections
        )
      ).previewContext(WidgetPreviewContext(family: .systemLarge))
      
      NFTYWidgetEntryView(
        entry: SimpleEntry(
          date: Date(),
          configuration: ConfigurationIntent(),collections:collections
        )
      ).previewContext(WidgetPreviewContext(family: .systemExtraLarge))
      
    }
  }
}
