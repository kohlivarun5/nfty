//
//  UsdText.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI
import BigInt

func formatter(symbol:String?) -> Formatter {
  let currencyFormatter = NumberFormatter()
  currencyFormatter.usesGroupingSeparator = true
  currencyFormatter.numberStyle = .currency
  // localize to your grouping and decimal separator
  currencyFormatter.locale = Locale.current
  switch(symbol) {
  case .some(let sym):
    currencyFormatter.currencySymbol = sym
  case .none:
    break
  }
  return currencyFormatter
}
var currencyFormatter = formatter(symbol:nil)
var ethFormatter = formatter(symbol:"Ξ")

struct UsdText: View {
  
  enum SpotState {
    case loading
    case localCurrency(Double)
    case unknown
  }
  
  @State private var spot : SpotState = .loading
  
  let wei:BigUInt
  let fontWeight : Font.Weight?
  var body: some View {
    switch(spot) {
    case .loading:
      ProgressView()
        .onAppear {
          switch(self.spot) {
          case .loading:
            EthSpot.get()
              .done(on:.main) { spot in
                switch(spot) {
                case .none:
                  self.spot = .unknown
                case .some(let rate):
                  self.spot = .localCurrency(rate)
                }
              }.catch { print ($0) }
          case .localCurrency,.unknown:
            break
          }
        }
    case .localCurrency(let rate):
      Text(currencyFormatter.string(for:((Double(wei) / 1e18) * rate))!)
        .fontWeight(fontWeight)
    case .unknown:
      Text(ethFormatter.string(for:(Double(wei) / 1e18))!)
        .fontWeight(fontWeight)
    }
  }
}

struct UsdText_Previews: PreviewProvider {
  static var previews: some View {
    UsdText(wei:BigUInt(2.2),fontWeight: nil)
  }
}
