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
      switch (userWallet.userAccount()) {
      case .none:
        ConnectWalletSheet(userWallet:userWallet)
      case .some(let account):
        VStack(spacing:0) {
          switch(self.tokensPage) {
          case .owned:
            WalletTokensView(tokens: getOwnerTokens(account))
          case .bids:
            ActivityView(account:account,kind:UserAccountOffers.Kind.bids,emptyMessage:"No Active Bids")
          case .sales:
            ActivityView(account:account,kind:UserAccountOffers.Kind.sales,emptyMessage:"No Active Sales")
          case .offers:
            ActivityView(account:account,kind:UserAccountOffers.Kind.offers,emptyMessage:"No Active Offers")
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
          .colorMultiply(.accentColor)
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
            .font(.title3)
            .padding(10)
        }
    )
    .sheet(isPresented: $showSettings) {
      UserSettingsView(userWallet: userWallet)
        .preferredColorScheme(.dark)
        .accentColor(.orange)
    }
  }
}


struct WalletView_Previews: PreviewProvider {
  static var previews: some View {
    WalletView()
  }
}
