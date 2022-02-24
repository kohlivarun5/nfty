//
//  UsdText.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI
import BigInt

func formatter(symbol:String?,maximumFractionDigits:Int?) -> Formatter {
  let currencyFormatter = NumberFormatter()
  currencyFormatter.usesGroupingSeparator = true
  currencyFormatter.numberStyle = .currency
  // localize to your grouping and decimal separator
  currencyFormatter.locale = Locale.current
  _ = maximumFractionDigits.map {
    currencyFormatter.maximumFractionDigits = $0
  }
  
  _ = symbol.map { currencyFormatter.currencySymbol = $0 }
  
  return currencyFormatter
}
var currencyFormatter = formatter(symbol:nil,maximumFractionDigits:nil)
var currencyFormatterWholeNumbers = formatter(symbol:nil,maximumFractionDigits:0)

func UsdString(wei:BigUInt,rate:Double) -> String {
  let amount = ((Double(wei) / 1e18) * rate)
  let formatter = amount >= 10000 ? currencyFormatterWholeNumbers : currencyFormatter
  return formatter.string(for:amount)!
}

var ethFormatter = formatter(symbol:"Ξ",maximumFractionDigits:3)

func EthString(wei:BigUInt) -> String {
  return ethFormatter.string(for:(Double(wei) / 1e18))!
}

var nearFormatter = formatter(symbol:"Ⓝ ",maximumFractionDigits:2)

func NearString(near:BigUInt) -> String {
  return nearFormatter.string(for:(Double(near) / 1e24))!
}

func PriceString(price:PriceUnit) -> String {
  switch(price) {
  case .wei(let wei):
    return EthString(wei: wei)
  case .near(let near):
    return NearString(near: near)
  }
}



struct UsdText: View {
  
  @ObservedObject private var spot = EthSpot.get()
  
  let price:PriceUnit
  let fontWeight : Font.Weight?
  var body: some View {
    
    switch(price) {
    case .near(let near):
      Text(NearString(near: near))
        .fontWeight(fontWeight)
    case .wei(let wei):
      
      
      ObservedPromiseView(
        data: spot,
        progress: { Text("") },
        view: { spot in
          switch(spot) {
          case .none:
            Text(EthString(wei: wei))
              .fontWeight(fontWeight)
          case .some(let rate):
            Text(UsdString(wei: wei, rate:rate))
              .fontWeight(fontWeight)
          }
        })
    }
  }
}

struct UsdEthVText: View {
  
  @ObservedObject private var spot = EthSpot.get()
  @StateObject var userSettings = UserSettings()
  
  let price:PriceUnit
  let fontWeight : Font.Weight?
  let alignment : HorizontalAlignment
  var body: some View {
    
    switch(price) {
    case .near(let near):
      Text(NearString(near: near))
        .fontWeight(fontWeight)
    case .wei(let wei):
      ObservedPromiseView(
        data: spot,
        progress: { Text("") },
        view: { spot in
          switch(spot) {
          case .none:
            Text(EthString(wei: wei))
              .fontWeight(fontWeight)
          case .some(let rate):
            
            switch(userSettings.quoteType) {
            case .Both:
              VStack(alignment:alignment) {
                Text(UsdString(wei: wei, rate:rate))
                  .fontWeight(fontWeight)
                Text(EthString(wei: wei))
                  .fontWeight(Font.Weight.light)
              }
            case .Fiat:
              Text(UsdString(wei: wei, rate:rate))
                .fontWeight(fontWeight)
            case .Crypto:
              Text(EthString(wei: wei))
                .fontWeight(fontWeight)
            }
            
          }
        })
    }
  }
}

struct UsdEthHText: View {
  
  @ObservedObject private var spot = EthSpot.get()
  @StateObject var userSettings = UserSettings()
  
  let price:PriceUnit
  let fontWeight : Font.Weight?
  var body: some View {
    
    switch(price) {
    case .near(let near):
      Text(NearString(near: near))
        .fontWeight(fontWeight)
    case .wei(let wei):
      ObservedPromiseView(
        data: spot,
        progress: { Text("") },
        view: { spot in
          switch(spot) {
          case .none:
            Text(EthString(wei: wei))
              .fontWeight(fontWeight)
          case .some(let rate):
            
            switch(userSettings.quoteType) {
            case .Both:
              HStack {
                Text(UsdString(wei: wei, rate:rate))
                  .fontWeight(fontWeight)
                Text("(\(EthString(wei: wei)))")
                  .fontWeight(Font.Weight.light)
              }
            case .Fiat:
              Text(UsdString(wei: wei, rate:rate))
                .fontWeight(fontWeight)
            case .Crypto:
              Text(EthString(wei: wei))
                .fontWeight(fontWeight)
            }
            
          }
        })
    }
  }
}

struct UsdText_Previews: PreviewProvider {
  static var previews: some View {
    UsdText(price:.wei(BigUInt(2.2)),fontWeight: nil)
  }
}
