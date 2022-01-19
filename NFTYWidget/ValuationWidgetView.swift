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
          .sorted { $0.info.floorPrice > $1.info.floorPrice };
        
        switch(widgetFamily) {
        case .systemSmall:
          EmptyView()
        case .systemMedium:
          EmptyView()
        case .systemLarge:
          EmptyView()
        case .systemExtraLarge:
          EmptyView()
        }
      }
    }
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
    .configurationDisplayName("Collections Valuation")
    .description("Valuation of the collections in wallet")
    .supportedFamilies([.systemSmall,.systemMedium,.systemLarge,.systemExtraLarge])
  }
}


struct ValuationWidgetView_Previews: PreviewProvider {
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
      ValuationWidgetView(
        entry: SimpleEntry(
          date: Date(),
          configuration: ConfigurationIntent(),collections:collections
        )
      ).previewContext(WidgetPreviewContext(family: .systemSmall))
      
      ValuationWidgetView(
        entry: SimpleEntry(
          date: Date(),
          configuration: ConfigurationIntent(),collections:collections
        )
      ).previewContext(WidgetPreviewContext(family: .systemMedium))
      
      ValuationWidgetView(
        entry: SimpleEntry(
          date: Date(),
          configuration: ConfigurationIntent(),collections:collections
        )
      ).previewContext(WidgetPreviewContext(family: .systemLarge))
      
      ValuationWidgetView(
        entry: SimpleEntry(
          date: Date(),
          configuration: ConfigurationIntent(),collections:collections
        )
      ).previewContext(WidgetPreviewContext(family: .systemExtraLarge))
      
    }
  }
}
