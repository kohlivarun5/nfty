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

func EthString(wei:BigUInt) -> String {
  return ethFormatter.string(for:(Double(wei) / 1e18))!
}

var ethFormatter = formatter(symbol:"Ξ",maximumFractionDigits:nil)

struct UsdText: View {
  
  @ObservedObject private var spot = EthSpot.get()
  
  let wei:BigUInt
  let fontWeight : Font.Weight?
  var body: some View {
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

struct UsdEthVText: View {
  
  @ObservedObject private var spot = EthSpot.get()
  
  let wei:BigUInt
  let fontWeight : Font.Weight?
  let alignment : HorizontalAlignment
  var body: some View {
    ObservedPromiseView(
      data: spot,
      progress: { Text("") },
      view: { spot in
        switch(spot) {
        case .none:
          Text(EthString(wei: wei))
            .fontWeight(fontWeight)
        case .some(let rate):
          VStack(alignment:alignment) {
            Text(UsdString(wei: wei, rate:rate))
              .fontWeight(fontWeight)
            Text(EthString(wei: wei))
              .fontWeight(Font.Weight.light)
          }
        }
      })
  }
}

struct UsdEthHText: View {
  
  @ObservedObject private var spot = EthSpot.get()
  
  let wei:BigUInt
  let fontWeight : Font.Weight?
  var body: some View {
    ObservedPromiseView(
      data: spot,
      progress: { Text("") },
      view: { spot in
        switch(spot) {
        case .none:
          Text(EthString(wei: wei))
            .fontWeight(fontWeight)
        case .some(let rate):
          HStack {
            Text(UsdString(wei: wei, rate:rate))
              .fontWeight(fontWeight)
            Text("(\(EthString(wei: wei)))")
              .fontWeight(Font.Weight.light)
          }
        }
      })
  }
}

struct UsdText_Previews: PreviewProvider {
  static var previews: some View {
    UsdText(wei:BigUInt(2.2),fontWeight: nil)
  }
}
