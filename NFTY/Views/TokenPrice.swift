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
    case loaded(NFTPriceInfo)
    case loading
    case none
  }
  @State private var wei : PriceState = .loading
  let price : TokenPriceType
  var body: some View {
    HStack {
      switch(wei) {
      case .loaded(let wei):
        VStack(alignment: .trailing) {
          switch(wei.price) {
          case .some(let wei):
            UsdText(wei:wei)
          case .none:
            EmptyView()
          }
          BlockTimeLabel(blockNumber:wei.blockNumber)
            .font(.footnote)
            .foregroundColor(.secondaryLabel)
        }
      case .none:
        EmptyView()
      case .loading:
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle())
          .scaleEffect(anchor: .center)
          .padding(.trailing)
      }
    }
    .animation(.none)
    .onAppear {
      DispatchQueue.global(qos:.userInteractive).async {
        switch(price) {
        case .eager(let wei):
          self.wei = .loaded(wei)
        case .lazy(let price):
          firstly {
            price
          }.done(on:.main) { wei in
            self.wei = .loaded(wei)
          }.catch { print($0) }
        }
      }
    }
  }
}

struct TokenPrice_Previews: PreviewProvider {
  static var previews: some View {
    TokenPrice(price:.eager(NFTPriceInfo(price:0,blockNumber: nil)))
  }
}
