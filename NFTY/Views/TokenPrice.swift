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
    VStack(alignment: .trailing) {
      switch(info.price) {
      case .some(let wei):
        UsdText(wei:wei)
          .foregroundColor(color(self.color))
      case .none:
        EmptyView()
      }
      BlockTimeLabel(blockNumber:info.blockNumber)
        .font(.footnote)
        .foregroundColor(subtleColor(self.color))
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
      VStack(alignment: .trailing) {
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
      progress:
        ProgressView()
        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
        .scaleEffect(anchor: .center)
        .padding(.trailing)) {
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
        TokenPriceLazy(status: status,color:color)
      }
    }.animation(.none)
  }
}

struct TokenPrice_Previews: PreviewProvider {
  static var previews: some View {
    TokenPrice(price:.eager(NFTPriceInfo(price:0,blockNumber: nil,type:.offer(TradeOfferInfo(from: SAMPLE_WALLET_ADDRESS)))),color:.label)
  }
}
