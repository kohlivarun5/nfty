//
//  ValuationWidgetView.swift
//  NFTYWidgetExtension
//
//  Created by Varun Kohli on 1/18/22.
//

import SwiftUI
import Intents
import WidgetKit
import BigInt

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
          .compactMap {
            switch($0.info.floorPrice,$0.info.prev_floor) {
            case (.wei(let floorWei),.wei(let prevWei)):
              return (Double(floorWei) / 1e18,Double(prevWei)/1e18,Double($0.info.ownedCount),$0.since)
            case (.wei,.near),(.near,.wei),(.near,.near):
              return nil
            }
          }
          .sorted {
            $0.0 * $0.2
            > $1.0 * $1.2
          };
        
        let nav = sorted.reduce(0, { accu,collection in
          return accu + (collection.0 * collection.2)
        });
        
        let nav_prev = sorted.reduce(0, { accu,collection in
          return accu + (collection.1 * collection.2)
        });
        
        let nav_pct_change = ((nav - nav_prev) / nav_prev);
        
        VStack {
          
          entry.spot.map { spot in
            HStack {
              Text(Formatters.fiat.string(for:(spot * nav))!)
                .font(.title2)
                .bold()
              Spacer()
            }
            .foregroundColor(.accentColor)
          }

          HStack {
            Text(Formatters.eth.string(for:nav)!)
              .font(.title2)
              .bold()
            Spacer()
          }
        }
          
        VStack {
          
          HStack {
            Spacer()
            Text(Formatters.percentage.string(for: nav_pct_change)!)
          }
          
          entry.spot.map { spot in
            HStack {
              Spacer()
              (Text("(")
               + Text(Formatters.fiat.string(for: ((nav - nav_prev) * spot))!)
               + Text(")"))
            }
          }
        }
        .foregroundColor(nav_pct_change < 0 ? Color.red : Color.green)
        
        VStack(spacing:0) {
          sorted.compactMap { $0.3 }.first.map { since in
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
        .padding(.top,10)
        
        
      }
    }
    .padding([.top,.leading,.trailing])
    .padding(.bottom,10)
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
              floorPrice: .wei(BigUInt(1e18 * 1.409))),
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
