//
//  WithWalletProviderView.swift
//  NFTY
//
//  Created by Varun Kohli on 8/26/21.
//

import SwiftUI

struct WithWalletProviderView<ProtectedView> : View where ProtectedView:View {
  @State private var showSheet = false
  @State private var walletProvider : WalletProvider?
  
  @ObservedObject var userWallet: UserWallet
  private let protectedView : (WalletProvider) -> ProtectedView
  
  init(userWallet: UserWallet,@ViewBuilder protectedView: @escaping (WalletProvider) -> ProtectedView) {
    self.userWallet = userWallet
    self.protectedView = protectedView
  }
  
  var body: some View {
    switch(walletProvider) {
    case .some(let walletProvider):
      protectedView(walletProvider)
    case .none:
      VStack {
        Text("Please sign in")
        ConnectWalletSheet(userWallet:userWallet)
      }
      .onAppear {
        self.walletProvider = userWallet.walletProvider()
      }
    }
  }
}

struct WithWalletProviderView_Previews: PreviewProvider {
    static var previews: some View {
        WithWalletProviderView(
          userWallet:UserWallet(),
          protectedView: { _ in EmptyView() }
        )
    }
}
