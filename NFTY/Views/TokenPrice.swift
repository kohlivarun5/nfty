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
  enum PriceState {
    case loaded(BigUInt)
    case loading
    case none
  }
  @State private var wei : PriceState = .loading
  let price : TokenPriceType
  var body: some View {
    HStack {
      switch(wei) {
      case .loaded(let wei):
        UsdText(wei:wei)
      case .none:
        EmptyView()
      case .loading:
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle())
          .scaleEffect(anchor: .center)
          .padding(.trailing)
      }
    }.onAppear {
      switch(price) {
      case .eager(let wei):
        switch(wei) {
        case .some(let wei):
          self.wei = .loaded(wei)
        case .none:
          self.wei = .none
        }
      case .lazy(let price):
        firstly {
          price
        }.done(on:.main) { wei in
          switch(wei) {
          case .some(let wei):
            self.wei = .loaded(wei)
          case .none:
            self.wei = .none
          }
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
