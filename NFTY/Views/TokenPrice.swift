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
  
  let hideIcon : Bool
  
  @StateObject var userSettings = UserSettings()
  
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
    case (.some(let price),.some(let blockNumber)):
      VStack {
        
        HStack(spacing:4) {
          switch(userSettings.quoteType) {
          case .Both,.Fiat:
            UsdText(price:price,fontWeight:.semibold)
              .foregroundColor(color(self.color))
          case .Crypto:
            Text(PriceString(price:price))
              .fontWeight(.semibold)
              .foregroundColor(color(self.color))
          }
          
          if (!hideIcon) {
            Image(systemName: TradeEventIcon.systemName(info.type))
              .font(.caption2)
          }
        }
        
        if (userSettings.quoteType == .Both && showEth) {
          Text(PriceString(price:price))
            .font(.body)
            .italic()
        }
        
        BlockTimeLabel(blockNumber:blockNumber)
          .font(.caption2)
          .foregroundColor(subtleColor(self.color))
      }
      
    case (.some(let price),.date(let date)):
      VStack {
        
        HStack(spacing:4) {
          switch(userSettings.quoteType) {
          case .Both,.Fiat:
            UsdText(price:price,fontWeight:.semibold)
              .foregroundColor(color(self.color))
          case .Crypto:
            Text(PriceString(price:price))
              .fontWeight(.semibold)
              .foregroundColor(color(self.color))
          }
          
          if (!hideIcon) {
            Image(systemName: TradeEventIcon.systemName(info.type))
              .font(.caption2)
          }
        }
        
        if (userSettings.quoteType == .Both && showEth) {
          Text(PriceString(price:price))
            .font(.body)
            .italic()
        }
        
        Text(date.timeAgoDisplay())
          .font(.caption2)
          .foregroundColor(subtleColor(self.color))
      }
      
    case (.none,.some(let blockNumber)):
      BlockTimeLabel(blockNumber:blockNumber)
        .font(.caption2)
        .foregroundColor(subtleColor(self.color))
        .padding([.top,.bottom],2)
    case (.none,.date(let date)):
      Text(date.timeAgoDisplay())
        .font(.caption2)
        .foregroundColor(subtleColor(self.color))
        .padding([.top,.bottom],2)
    case (.some(let price),.none):
      HStack {
        UsdEthVText(price:price,fontWeight:.semibold,alignment:.center)
          .foregroundColor(color(self.color))
        if (!hideIcon) {
          Image(systemName: TradeEventIcon.systemName(info.type))
            .font(.caption2)
        }
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
  
  let hideIcon : Bool
  
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
      TokenPriceKnown(info:info,color:color,showEth: showEth,hideIcon:hideIcon)
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
    case .unavailable:
      Text(" ··· ")
        .padding([.leading,.trailing],5)
    }
  }
}

struct TokenPriceLazy : View {
  @ObservedObject var status : ObservablePromise<NFTPriceStatus>
  
  let color : Style
  let showEth : Bool
  
  let hideIcon : Bool
  
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
        TokenPriceStatus(status:$0,color:color,showEth: showEth,hideIcon:hideIcon)
      }
  }
}

struct TokenPrice: View {
  let price : TokenPriceType
  let color : Style
  
  let hideIcon : Bool
  
  var body: some View {
    HStack {
      switch (price) {
      case .eager(let info):
        TokenPriceKnown(info:info,color:color,showEth: false,hideIcon:hideIcon)
      case .lazy(let status):
        TokenPriceLazy(status: status(),color:color,showEth: false,hideIcon:hideIcon)
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
        TokenPriceKnown(info:info,color:color,showEth: true,hideIcon:false)
      case .lazy(let status):
        TokenPriceLazy(status: status(),color:color,showEth: true,hideIcon:false)
      }
    }.padding([.leading,.trailing],5)
  }
}

struct TokenPrice_Previews: PreviewProvider {
  static var previews: some View {
    TokenPrice(price:.eager(NFTPriceInfo(wei:0,blockNumber: nil,type:.ask)),color:.label,hideIcon:false)
  }
}
