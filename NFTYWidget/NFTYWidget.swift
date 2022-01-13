//
//  NFTYWidget.swift
//  NFTYWidget
//
//  Created by Varun Kohli on 1/11/22.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(date: Date(), configuration: ConfigurationIntent(),collections:[
      CollectionStats(id: "a", name: "CryptoMories", floorPrice: 1.409,change:0.5213123,changeSince: Date.now),
      CollectionStats(id: "b", name: "Illuminati", floorPrice: 0.5,change:-0.123131,changeSince: Date.now),
    ])
  }
  
  func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
    print("getSnapshot")
    completion(placeholder(in:context))
  }
  
  func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
    print("getTimeline")
    
    fetchStats()
      .done { collections in
        print("Collections=\(collections)")
        
        let entries = [
          SimpleEntry(date: Date(), configuration: configuration,collections:collections)
        ]
        
        let refresh = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
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
    VStack(spacing:15) {
      
      if (entry.collections.isEmpty) {
        Text("No Collections in Wallet")
          .multilineTextAlignment(.center)
          .foregroundColor(.secondary)
      } else {
        
        ForEach(entry.collections) { stats in
          VStack(spacing:5) {
            HStack {
              Text(stats.name)
                .foregroundColor(.secondary)
                .bold()
            }
            .font(.subheadline)
            HStack(spacing:0) {
              Text(Formatters.eth.string(for:stats.floorPrice)!)
                .bold()
                .frame(alignment: .leading)
              Spacer()
              Text("\(stats.change < 0 ? "▼" : "▲") "+Formatters.percentage.string(for: stats.change)!)
                .foregroundColor(stats.change < 0 ? Color.red : Color.green)
                .frame(alignment: .trailing)
            }
            .font(.footnote)
          }
          .padding([.leading,.trailing],15)
        }
      }
    }
  }
}

@main
struct NFTYWidget: Widget {
  let kind: String = "NFTY"
  
  var body: some WidgetConfiguration {
    IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
      NFTYWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Collections Floor")
    .description("Show floor price for relevant collections")
  }
}

struct NFTYWidget_Previews: PreviewProvider {
  static var previews: some View {
    NFTYWidgetEntryView(
      entry: SimpleEntry(
        date: Date(),
        configuration: ConfigurationIntent(),collections:[
          CollectionStats(id: "a", name: "CryptoMories", floorPrice: 1.409,change:0.5213123,changeSince: Date.now),
          CollectionStats(id: "b", name: "Illuminati", floorPrice: 0.4,change:-0.123131,changeSince: Date.now),
          CollectionStats(id: "c", name: "Illuminati", floorPrice: 0.4,change:-0.123131,changeSince: Date.now),
        ]
      )
    ).previewContext(WidgetPreviewContext(family: .systemSmall))
  }
}
