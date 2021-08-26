//
//  TokenPrice.swift
//  NFTY
//
//  Created by Varun Kohli on 4/27/21.
//

import SwiftUI
import BigInt

enum Style {
  case label
  case dark
}

struct TokenPriceKnown : View {
  let info : NFTPriceInfo
  let color : Style
  let showEth : Bool
  
  private func color(_ color:Style) -> Color {
    switch(color){
    case .label:
      return Color.label
    case .dark:
      return Color.black
    }
  }
  
  private func subtleColor(_ color:Style) -> Color {
    switch(color){
    case .label:
      return Color.secondaryLabel
    case .dark:
      return Color.gray
    }
  }
  
  var body: some View {
    switch(info.price,info.blockNumber) {
    case (.some(let wei),.some(let blockNumber)):
      VStack {
        
        HStack {
          UsdText(wei:wei,fontWeight:.semibold)
            .foregroundColor(color(self.color))
          Image(systemName: TradeEventIcon.systemName(info.type))
            .font(.caption2)
        }
        
        if (showEth) {
          Text(ethFormatter.string(for:(Double(wei) / 1e18))!)
            .font(.body)
            .italic()
        }
        
        BlockTimeLabel(blockNumber:blockNumber)
          .font(.caption2)
          .foregroundColor(subtleColor(self.color))
      }
    case (.none,.some(let blockNumber)):
      BlockTimeLabel(blockNumber:blockNumber)
        .font(.caption2)
        .foregroundColor(subtleColor(self.color))
        .padding([.top,.bottom],2)
    case (.some(let wei),.none):
      HStack {
        UsdText(wei:wei,fontWeight:.semibold)
          .foregroundColor(color(self.color))
        Image(systemName: TradeEventIcon.systemName(info.type))
          .font(.caption2)
      }
    case (.none,.none):
      EmptyView()
    }
  }
}

struct TokenPriceStatus : View {
  let status : NFTPriceStatus
  
  let color : Style
  let showEth : Bool
  
  private func color(_ color:Style) -> Color {
    switch(color){
    case .label:
      return Color.label
    case .dark:
      return Color.black
    }
  }
  
  private func subtleColor(_ color:Style) -> Color {
    switch(color){
    case .label:
      return Color.secondaryLabel
    case .dark:
      return Color.gray
    }
  }
  
  var body: some View {
    switch(status) {
    case .known(let info):
      TokenPriceKnown(info:info,color:color,showEth: showEth)
    case .notSeenSince(let since):
      VStack {
        Text("Not seen since")
        BlockTimeLabel(blockNumber:since.blockNumber)
      }
      .font(.footnote)
      .foregroundColor(subtleColor(self.color))
    case .burnt:
      Text("Burnt")
        .font(.footnote)
        .foregroundColor(subtleColor(self.color))
    }
  }
}

struct TokenPriceLazy : View {
  @ObservedObject var status : ObservablePromise<NFTPriceStatus>
  
  let color : Style
  let showEth : Bool
  
  private func subtleColor(_ color:Style) -> Color {
    switch(color){
    case .label:
      return Color.secondaryLabel
    case .dark:
      return Color.gray
    }
  }
  
  var body: some View {
    ObservedPromiseView(
      data: status,
      progress: {
        Text(" ··· ")
          .padding([.leading,.trailing],5)
      }) {
      TokenPriceStatus(status:$0,color:color,showEth: showEth)
    }
  }
}

struct TokenPrice: View {
  let price : TokenPriceType
  let color : Style
  
  var body: some View {
    HStack {
      switch (price) {
      case .eager(let info):
        TokenPriceKnown(info:info,color:color,showEth: false)
      case .lazy(let status):
        TokenPriceLazy(status: status(),color:color,showEth: false)
      }
    }.padding([.leading,.trailing],5)
  }
}

struct TokenPriceWithEth: View {
  let price : TokenPriceType
  let color : Style
  
  var body: some View {
    HStack {
      switch (price) {
      case .eager(let info):
        TokenPriceKnown(info:info,color:color,showEth: true)
      case .lazy(let status):
        TokenPriceLazy(status: status(),color:color,showEth: true)
      }
    }.padding([.leading,.trailing],5)
  }
}

struct TokenPrice_Previews: PreviewProvider {
  static var previews: some View {
    TokenPrice(price:.eager(NFTPriceInfo(price:0,blockNumber: nil,type:.ask)),color:.label)
  }
}
