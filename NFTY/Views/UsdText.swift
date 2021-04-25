//
//  UsdText.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI
import BigInt

func formatter() -> Formatter {
    let currencyFormatter = NumberFormatter()
    currencyFormatter.usesGroupingSeparator = true
    currencyFormatter.numberStyle = .currency
    // localize to your grouping and decimal separator
    currencyFormatter.locale = Locale.current
    return currencyFormatter
}
var currencyFormatter = formatter()
var USD_PER_ETH=2300.0;

struct UsdText: View {
    var wei:BigUInt
    var body: some View {
        Text(currencyFormatter.string(for:(Double(wei / BigUInt(1e18)) * USD_PER_ETH))!)
    }
}

struct UsdText_Previews: PreviewProvider {
    static var previews: some View {
        UsdText(wei:BigUInt(2.2))
    }
}
