//
//  WalletView.swift
//  NFTY
//
//  Created by Varun Kohli on 5/9/21.
//

import SwiftUI

import PromiseKit
import BigInt
import Web3

struct WalletView: View {
  

  @State private var showAddressSheet = false
  @State private var address : EthereumAddress? = nil
  
  
  var body: some View {
    
    VStack {
      switch (address) {
      case .none:
        Text("Wallet not connected")
          .font(.title)
          .foregroundColor(.secondary)
      case .some(let address):
        WalletTokensView(tokens: NftOwnerTokens(ownerAddress: address))
      }
    }
    .toolbar {
      Button(action: {
        self.showAddressSheet = true
      }) {
        Image(systemName:"signature")
      }
    }
    .sheet(isPresented: $showAddressSheet) {
      ConnectWalletSheet(address:$address)
    }
  }
}


struct WalletView_Previews: PreviewProvider {
    static var previews: some View {
      WalletView()
    }
}
