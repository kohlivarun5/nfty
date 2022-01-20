//
//  ValuationWidgetView.swift
//  NFTYWidgetExtension
//
//  Created by Varun Kohli on 1/18/22.
//

import SwiftUI
import Intents
import WidgetKit

struct ValuationWidgetView: View {
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
          .sorted {
            $0.info.floorPrice * Double($0.info.ownedCount)
            > $1.info.floorPrice * Double($1.info.ownedCount) };
        
        let nav = sorted.reduce(0, { accu,collection in
          return accu + (collection.info.floorPrice * Double(collection.info.ownedCount))
        });
        
        let nav_prev = sorted.reduce(0, { accu,collection in
          return accu + (collection.prev_floor * Double(collection.info.ownedCount))
        });
        
        let nav_pct_change = ((nav - nav_prev) / nav_prev);
        
        VStack {
          
          entry.spot.map { spot in
            HStack {
              Spacer()
              Text(Formatters.fiat.string(for:(spot * nav))!)
                .font(.title2)
                .bold()
            }
          }

          HStack {
            Spacer()
            Text(Formatters.eth.string(for:nav)!)
              .font(.title2)
              .bold()
          }
          
          VStack {
            switch(entry.spot) {
            case .none:
              HStack {
                Spacer()
                Text(Formatters.percentage.string(for: nav_pct_change)!)
              }
            case .some(let spot):
              HStack {
                Text(Formatters.percentage.string(for: nav_pct_change)!)
                Spacer()
                (Text("(")
                 + Text(Formatters.fiat.string(for: (nav_pct_change * spot))!)
                 + Text(")"))
              }
            }
          }
          .foregroundColor(nav_pct_change < 0 ? Color.red : Color.green)
          
        }
      }
    }
    .padding()
  }
}

struct ValuationWidget: Widget {
  let kind: String = "NFTY Valuations"
  
  var body: some WidgetConfiguration {
    IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
      ValuationWidgetView(entry: entry)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .environment(\.colorScheme,.dark)
        .accentColor(Color.orange)
    }
    .configurationDisplayName("Valuation")
    .description("Valuation of the collections in wallet")
    .supportedFamilies([.systemSmall])
  }
}


struct ValuationWidgetView_Previews: PreviewProvider {
  static var previews: some View {
    let collections : [CollectionStats] = {
      return Array(0...100)
        .map {
          CollectionStats(
            info:CollectionFloorData(
              id: "\($0)",
              name: "CryptoMories\($0)",
              ownedCount: $0,
              floorPrice: 1.409),
            prev_floor:1.2,
            percent_change:$0.isMultiple(of: 2) ? 0.5213123 : -0.23,
            since:Date())
        }
    }()
    
    Group {
      ValuationWidgetView(
        entry: SimpleEntry(
          date: Date(),
          configuration: ConfigurationIntent(),
          spot:3000,
          collections:collections
        )
      ).previewContext(WidgetPreviewContext(family: .systemSmall))
      
      ValuationWidgetView(
        entry: SimpleEntry(
          date: Date(),
          configuration: ConfigurationIntent(),
          spot:3000,
          collections:collections
        )
      ).previewContext(WidgetPreviewContext(family: .systemMedium))
      
      ValuationWidgetView(
        entry: SimpleEntry(
          date: Date(),
          configuration: ConfigurationIntent(),
          spot:3000,
          collections:collections
        )
      ).previewContext(WidgetPreviewContext(family: .systemLarge))
      
      ValuationWidgetView(
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
