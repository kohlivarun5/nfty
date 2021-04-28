//
//  TokenPrice.swift
//  NFTY
//
//  Created by Varun Kohli on 4/27/21.
//

import SwiftUI
import BigInt
import PromiseKit

struct TokenPrice: View {
  @State private var wei : BigUInt?
  let price : TokenPriceType
  var body: some View {
    HStack {
      switch(wei) {
      case .some(let wei):
        UsdText(wei:wei)
      case .none:
        EmptyView()
      }
    }.onAppear {
      print(price);
      switch(price) {
      case .eager(let wei):
        self.wei = wei
      case .lazy(let price):
        firstly {
          price
        }.done(on:.main) { wei in
          self.wei = wei
        }.catch { print($0) }
      }
    }
  }
}

struct TokenPrice_Previews: PreviewProvider {
  static var previews: some View {
    TokenPrice(price:.eager(0))
  }
}
