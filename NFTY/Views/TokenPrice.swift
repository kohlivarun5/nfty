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
    case burnt
    case notSeenSince(NFTNotSeenSince)
    case loaded(NFTPriceInfo)
    case loading
    case none
  }
  @State private var wei : PriceState = .loading
  let price : TokenPriceType
  
  enum Style {
    case label
    case dark
  }
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
    HStack {
      switch(wei) {
      case .loaded(let wei):
        VStack(alignment: .trailing) {
          switch(wei.price) {
          case .some(let wei):
            UsdText(wei:wei)
              .foregroundColor(color(self.color))
          case .none:
            EmptyView()
          }
          BlockTimeLabel(blockNumber:wei.blockNumber)
            .font(.footnote)
            .foregroundColor(subtleColor(self.color))
        }
      case .none:
        EmptyView()
      case .loading:
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle(tint: .gray))
          .scaleEffect(anchor: .center)
          .padding(.trailing)
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
            switch(wei) {
            case .known(let w):
              self.wei = .loaded(w)
            case .notSeenSince(let b):
              self.wei = .notSeenSince(b)
            case .burnt:
              self.wei = .burnt
            }
            
          }.catch { print($0) }
        }
      }
    }
  }
}

struct TokenPrice_Previews: PreviewProvider {
  static var previews: some View {
    TokenPrice(price:.eager(NFTPriceInfo(price:0,blockNumber: nil)),color:.label)
  }
}
