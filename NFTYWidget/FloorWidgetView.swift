//
//  FloorWidgetView.swift
//  NFTYWidgetExtension
//
//  Created by Varun Kohli on 1/18/22.
//

import SwiftUI
import WidgetKit
import BigInt

struct FloorWidgetStackView : View {
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
            .lineLimit(1)
        }
        .colorMultiply(.accentColor)
        .font(.subheadline)
        
        HStack(spacing:0) {
          Text(Formatters.PriceString(stats.info.floorPrice))
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


struct FloorWidgetView : View {
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
          FloorWidgetStackView(collections:sorted.prefix(3))
        case .systemMedium:
          LazyVGrid(
            columns: Array(
              repeating:GridItem(.flexible(maximum:140),spacing:20),
              count:2
            ),spacing:8
          ) {
            FloorWidgetStackView(collections:sorted.prefix(6))
          }
        case .systemLarge:
          LazyVGrid(
            columns: Array(
              repeating:GridItem(.flexible(maximum:140),spacing:20),
              count:2
            ),spacing:8
          ) {
            FloorWidgetStackView(collections:sorted.prefix(12))
          }
          
        case .systemExtraLarge:
          LazyVGrid(
            columns: Array(
              repeating:GridItem(.flexible(maximum:140),spacing:20),
              count:4
            ),spacing:8
          ) {
            FloorWidgetStackView(collections:sorted.prefix(24))
          }
        case .accessoryCircular,.accessoryRectangular,.accessoryInline:
          EmptyView()
        }
        
        switch(widgetFamily) {
        case .systemSmall:
          
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
        case .systemMedium,.systemLarge,.systemExtraLarge:
          HStack {
            (Text("Updated ") + Text(entry.date, style: .relative) + Text(" ago"))
              .font(.system(size:7))
              .foregroundColor(Color.secondaryLabel)
            
            Spacer()
            sorted.compactMap { $0.since }.first.map { since in
              Text("Change since \(since.timeAgoDisplay())")
                .font(.system(size:7))
                .foregroundColor(Color.secondaryLabel)
            }
          }
        case .accessoryCircular,.accessoryRectangular,.accessoryInline:
          EmptyView()
        }
      }
    }
    .padding([.leading,.trailing])
    .padding(.top,10)
    .padding(.bottom,7)
  }
}


struct FloorWidget: Widget {
  let kind: String = "NFTY floors"
  
  var body: some WidgetConfiguration {
    IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
      FloorWidgetView(entry: entry)
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


struct FloorWidgetView_Previews: PreviewProvider {
  static var previews: some View {
    
    let collections : [CollectionStats] = {
      return Array(0...100)
        .map {
          CollectionStats(
            info:CollectionFloorData(
              id: "\($0)",
              name: "CryptoMories\($0)",
              ownedCount: $0,
              floorPrice: .wei(BigUInt(1e18 * 1.409))),
            prev_floor:.wei(BigUInt(1e18 * 1.2)),
            percent_change:$0.isMultiple(of: 2) ? 0.5213123 : -0.23,
            since:Date())
        }
    }()
    
    Group {
      FloorWidgetView(
        entry: SimpleEntry(
          date: Date(),
          configuration: ConfigurationIntent(),
          spot:3000,
          collections:collections
        )
      ).previewContext(WidgetPreviewContext(family: .systemSmall))
      
      FloorWidgetView(
        entry: SimpleEntry(
          date: Date(),
          configuration: ConfigurationIntent(),
          spot:3000,
          collections:collections
        )
      ).previewContext(WidgetPreviewContext(family: .systemMedium))
      
      FloorWidgetView(
        entry: SimpleEntry(
          date: Date(),
          configuration: ConfigurationIntent(),
          spot:3000,
          collections:collections
        )
      ).previewContext(WidgetPreviewContext(family: .systemLarge))
      
      FloorWidgetView(
        entry: SimpleEntry(
          date: Date(),
          configuration: ConfigurationIntent(),
          spot:3000,
          collections:collections
        )
      ).previewContext(WidgetPreviewContext(family: .systemExtraLarge))
      
    }
  }
}
