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
          .onAppear {
            if let addr = UserDefaults.standard.string(forKey: UserDefaultsKeys.walletAddress.rawValue) {
              self.address = try? EthereumAddress(hex:addr,eip55: false)
            }
          }
      case .some(let address):
        WalletTokensView(tokens: NftOwnerTokens(ownerAddress: address))
      }
    }
    .toolbar {
      Button(action: {
        self.showAddressSheet = true
      }) {
        Image(systemName:"link.badge.plus")
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
