//
//  UsdText.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI

func formatter() -> Formatter {
    let currencyFormatter = NumberFormatter()
    currencyFormatter.usesGroupingSeparator = true
    currencyFormatter.numberStyle = .currency
    // localize to your grouping and decimal separator
    currencyFormatter.locale = Locale.current
    return currencyFormatter
}
var currencyFormatter = formatter()
var USD_PER_ETH=2200.0;

struct UsdText: View {
    var eth:Double
    var body: some View {
        Text(currencyFormatter.string(for:(eth * USD_PER_ETH))!)
    }
}

struct UsdText_Previews: PreviewProvider {
    static var previews: some View {
        UsdText(eth:2.2)
    }
}
