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
  
  private func title(_ tokensPage:TokensPage) -> String {
    switch(self.tokensPage) {
    case .owned:
      return "Wallet"
    case .bids:
      return "Bids"
    case .sales:
      return "Sales"
    case .offers:
      return "Offers"
    }
  }
  
  var body: some View {
    
    VStack {
      switch (userWallet.walletAddress) {
      case .none:
        ConnectWalletSheet(userWallet:userWallet)
          .environmentObject(userWallet)
      case .some(let address):
        VStack(spacing:0) {
          
          switch(self.tokensPage) {
          case .owned:
            WalletTokensView(tokens: getOwnerTokens(address))
          case .bids:
            ActivityView(address:.maker(address),side:OpenSeaApi.Side.buy,emptyMessage:"No Active Bids")
          case .sales:
            ActivityView(address:.maker(address),side:OpenSeaApi.Side.sell,emptyMessage:"No Active Sales")
          case .offers:
            ActivityView(address:.owner(address),side:OpenSeaApi.Side.buy,emptyMessage:"No Active Offers")
          }
          
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
          .padding([.trailing,.leading])
          .padding(.top,5)
          .padding(.bottom,7)
          
        }
        
      }
    }
    .navigationBarTitle(title(self.tokensPage),displayMode: .inline)
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
      UserSettingsView(userWallet: userWallet)
    }
  }
}


struct WalletView_Previews: PreviewProvider {
  static var previews: some View {
    WalletView()
  }
}
