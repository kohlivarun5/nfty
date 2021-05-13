//
//  TokenPrice.swift
//  NFTY
//
//  Created by Varun Kohli on 4/27/21.
//

import SwiftUI
import BigInt
import Web3

struct UserProfileButton : View {
  
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  
  let address : EthereumAddress?
    
  var body : some View {
    switch (address.flatMap { addressIfNotZero($0) }) {
    case .none:
      Image(systemName: "flame.fill")
    case .some (let address):
      NavigationLink(
        destination:
          WalletTokensView(tokens: NftOwnerTokens(ownerAddress:address))
          .navigationBarTitle("User Profile")
          .navigationBarBackButtonHidden(true)
          .navigationBarItems(leading: Button(action: {presentationMode.wrappedValue.dismiss()}, label: { BackButton() }))
      ) {
        Image(systemName: "person.crop.circle")
      }
    }
  }
}

struct TokenPriceEventKnown : View {
  var info : NFTPriceInfo
  var color : Color
  
  init(info:NFTPriceInfo,color:Color) {
    print(info)
    self.info = info
    self.color = color
  }
  
  var body: some View {
    VStack(alignment: .leading) {
      switch(info.type) {
      case .offer(let info):
        UserProfileButton(address: info.from)
      case .bought(let info):
          UserProfileButton(address: info.to)
      case .transfer(let info):
          UserProfileButton(address: info.to)
      }
    }
    .foregroundColor(color)
    .font(.largeTitle)
    .frame(width: 44, height: 44)
  }
}

struct TokenPriceEventStatus : View {
  let status : NFTPriceStatus
  let color : Color
  
  var body: some View {
    switch(status) {
    case .known(let info):
      TokenPriceEventKnown(info:info,color:color)
    default:
      EmptyView() // Should have some owner or address
    }
  }
}

struct TokenPriceEventLazy : View {
  @ObservedObject var status : ObservablePromise<NFTPriceStatus>
  let color : Color
  
  var body: some View {
    ObservedPromiseView(
      data: status,
      progress:
        ProgressView()
        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
        .scaleEffect(anchor: .center)
        .padding(.trailing)) {
      TokenPriceEventStatus(status:$0,color:color)
    }
  }
}

struct TokenPriceEventView: View {
  let price : TokenPriceType
  
  let color : Color
  
  var body: some View {
    HStack {
      switch (price) {
      case .eager(let info):
        TokenPriceEventKnown(info:info,color:color)
      case .lazy(let status):
        TokenPriceEventLazy(status: status,color:color)
      }
    }.animation(.none)
  }
}

struct TokenPriceEvent_Previews: PreviewProvider {
  static var previews: some View {
    TokenPriceEventView(price:.eager(NFTPriceInfo(price:0,blockNumber: nil,type:.offer(TradeOfferInfo(from: SAMPLE_WALLET_ADDRESS,to:SAMPLE_WALLET_ADDRESS)))),color:.label)
  }
}
