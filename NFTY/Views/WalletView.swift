//
//  WalletView.swift
//  NFTY
//
//  Created by Varun Kohli on 5/9/21.
//

import SwiftUI

import BigInt
import Web3

struct WalletView: View {
  
  @State private var showSettings = false
  @EnvironmentObject var userWallet: UserWallet
  
  enum TokensPage : Int {
    case owned
    case bids
    case sales
    case offers
  }
  
  @State private var tokensPage : TokensPage = .owned
  
  var body: some View {
    
    VStack {
      switch (userWallet.walletAddress) {
      case .none:
        ConnectWalletSheet()
      case .some(let address):
        VStack {
          Picker(selection: Binding<Int>(
                  get: { self.tokensPage.rawValue },
                  set: { tag in
                    withAnimation { // needed explicit for transitions
                      self.tokensPage = TokensPage(rawValue: tag)!
                    }
                  }),
                 label: Text("")) {
            Text("Owned").tag(TokensPage.owned.rawValue)
            Text("Bids").tag(TokensPage.bids.rawValue)
            Text("Sales").tag(TokensPage.sales.rawValue)
            Text("Offers").tag(TokensPage.offers.rawValue)
          }
          .pickerStyle(SegmentedPickerStyle())
          .colorMultiply(.orange)
          
          Spacer()
          // https://stackoverflow.com/questions/59689342/swipe-between-two-pages-with-segmented-style-picker-in-swiftui
          ZStack {
            //Rectangle().fill(Color.clear)
            switch(self.tokensPage) {
            case .owned:
              WalletTokensView(tokens: getOwnerTokens(address))
            case .bids:
              ActivityView(address:.maker(address),side:OpenSeaApi.Side.buy)
            case .sales:
              ActivityView(address:.maker(address),side:OpenSeaApi.Side.sell)
            case .offers:
              ActivityView(address:.owner(address),side:OpenSeaApi.Side.buy)
            }
          }
        }
        
      }
    }
    .navigationBarItems(
      trailing:
        Button(action: {
          self.showSettings = true
        }) {
          Image(systemName:"gearshape")
            .accentColor(.orange)
            .font(.title3)
            .padding(10)
        }
    )
    .sheet(isPresented: $showSettings) {
      UserSettingsView()
    }
  }
}


struct WalletView_Previews: PreviewProvider {
  static var previews: some View {
    WalletView()
  }
}
