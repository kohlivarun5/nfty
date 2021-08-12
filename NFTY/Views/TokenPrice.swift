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
    VStack {
      switch(info.price) {
      case .some(let wei):
        HStack {
          UsdText(wei:wei,fontWeight:.semibold)
            .foregroundColor(color(self.color))
          Image(systemName: TradeEventIcon.systemName(info.type))
            .font(.caption2)
        }
      case .none:
        EmptyView()
      }
      BlockTimeLabel(blockNumber:info.blockNumber)
        .font(.caption2)
        .foregroundColor(subtleColor(self.color))
        .padding([.top,.bottom],info.price == nil ? 2 : 0)
        .padding([.leading,.trailing],2)
    }
  }
}

struct TokenPriceStatus : View {
  let status : NFTPriceStatus
  
  let color : Style
  
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
      TokenPriceKnown(info:info,color:color)
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
          .padding([.leading,.trailing])
      }) {
      TokenPriceStatus(status:$0,color:color)
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
        TokenPriceKnown(info:info,color:color)
      case .lazy(let status):
        TokenPriceLazy(status: status(),color:color)
      }
    }
  }
}

struct TokenPrice_Previews: PreviewProvider {
  static var previews: some View {
    TokenPrice(price:.eager(NFTPriceInfo(price:0,blockNumber: nil,type:.ask)),color:.label)
  }
}
