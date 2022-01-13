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
  let change : (percentage:Double,since:Date)?
}

struct Provider: IntentTimelineProvider {
  
  struct FloorPrice : Codable {
    let floorPrice : Double
    let date : Date
  }
  
  private var lastPriceCache = try! DiskStorage<String, FloorPrice>(
    config: DiskConfig(name: "Provider.FloorsCache",expiry: .never),
    transformer:TransformerFactory.forCodable(ofType:FloorPrice.self))
  
  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(date: Date(), configuration: ConfigurationIntent(),collections:[
      CollectionStats(
        info:CollectionFloorData(id: "a", name: "CryptoMories", floorPrice: 1.409),
        change:(percentage:0.5213123,since:Date())
      ),
      CollectionStats(
        info:CollectionFloorData(id: "b", name: "Illuminati", floorPrice: 1.409),
        change:(percentage:-0.213123,since:Date())
      )
    ])
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
                let stats = CollectionStats(
                  info: info,
                  change:
                    (try? lastPriceCache.object(forKey:info.id))
                    .flatMap {
                      $0.floorPrice == info.floorPrice
                      ? nil
                      : (percentage: ($0.floorPrice - info.floorPrice) / info.floorPrice, since:$0.date)
                    }
                )
                
                switch(try? lastPriceCache.object(forKey:info.id)) {
                case .none:
                  try? lastPriceCache.setObject(FloorPrice(floorPrice:info.floorPrice,date:date),forKey:info.id)
                case .some(let floor):
                  if (date.timeIntervalSince(floor.date) >= (60 * 60 * 6)) { // Only update every 6 hours
                    try? lastPriceCache.setObject(FloorPrice(floorPrice:info.floorPrice,date:date),forKey:info.id)
                  }
                }
                print(stats)
                return stats
              }
          )
        ]
        
        let refresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
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
    formatter.positivePrefix = formatter.plusSign
    formatter.negativePrefix = formatter.minusSign
    formatter.maximumFractionDigits = 2
    return formatter
  }()
}

struct NFTYWidgetEntryView : View {
  var entry: Provider.Entry
  
  var body: some View {
    VStack(spacing:8) {
      
      if (entry.collections.isEmpty) {
        Text("No Collections in Wallet")
          .multilineTextAlignment(.center)
          .foregroundColor(.secondary)
      } else {
        
        ForEach(
          Array(
            entry.collections
              .sorted { $0.info.floorPrice > $1.info.floorPrice }
              .prefix(3)
          ),
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
              
              switch(stats.change) {
              case .none:
                Text("unch")
                  .foregroundColor(.secondary)
                  .frame(alignment: .trailing)
              case .some(let (percentage,_)):
                
                Text("\(percentage < 0 ? "▼" : "▲") "+Formatters.percentage.string(for: percentage)!)
                  .foregroundColor(percentage < 0 ? Color.red : Color.green)
                  .frame(alignment: .trailing)
              }
            }.font(.footnote)
          }
        }
        
        entry.collections.compactMap { $0.change }.first.map { change in
          HStack {
            Spacer()
            Text("Change since \(change.since.timeAgoDisplay())")
              .font(.system(size:7))
              .foregroundColor(Color.secondaryLabel)
          }
        }
        
      }
    }
    .padding([.leading,.trailing])
    .padding(.top,10)
    .padding(.bottom,5)
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
    .supportedFamilies([.systemSmall])
  }
}

struct NFTYWidget_Previews: PreviewProvider {
  static var previews: some View {
    NFTYWidgetEntryView(
      entry: SimpleEntry(
        date: Date(),
        configuration: ConfigurationIntent(),collections:[
          
          CollectionStats(
            info:CollectionFloorData(id: "a", name: "CryptoMories", floorPrice: 1.409),
            change:(percentage:0.5213123,since:Date())
          ),
          CollectionStats(
            info:CollectionFloorData(id: "b", name: "Illuminati", floorPrice: 1.409),
            change:(percentage:0.5213123,since:Date())
          ),
          CollectionStats(
            info:CollectionFloorData(id: "c", name: "Illuminati", floorPrice: 1.409),
            change:(percentage:0.5213123,since:Date())
          )
        ]
      )
    ).previewContext(WidgetPreviewContext(family: .systemSmall))
  }
}
