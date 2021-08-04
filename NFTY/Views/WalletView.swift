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
  
  @State private var showAddressSheet = false
  @EnvironmentObject var userWallet: UserWallet
  
  var body: some View {
    
    VStack {
      switch (userWallet.walletAddress) {
      case .none:
        ConnectWalletSheet()
      case .some(let address):
        WalletTokensView(tokens: getOwnerTokens(address))
      }
    }
    .navigationBarItems(
      trailing:
        Button(action: {
          self.showAddressSheet = true
        }) {
          Image(systemName:"gearshape")
            .renderingMode(.original)
            .accentColor(.orange)
            .font(.title3)
            .padding(10)
        }
    )
    .sheet(isPresented: $showAddressSheet) {
      ConnectWalletSheet()
    }
  }
}


struct WalletView_Previews: PreviewProvider {
  static var previews: some View {
    WalletView()
  }
}
