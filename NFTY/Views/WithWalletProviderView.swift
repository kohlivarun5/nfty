//
//  WithWalletProviderView.swift
//  NFTY
//
//  Created by Varun Kohli on 8/26/21.
//

import SwiftUI

struct WithWalletProviderView<ButtonView,ProtectedView> : View where ButtonView:View, ProtectedView : View {
  
  @State private var showSheet = false
  @State private var walletProvider : WalletProvider? = nil
  
  @ObservedObject var userWallet: UserWallet
  
  
  private let label : () -> ButtonView
  private let content : (WalletProvider) -> ProtectedView
  
  init(
    userWallet: UserWallet,
    @ViewBuilder label:@escaping () -> ButtonView,
    @ViewBuilder content: @escaping (WalletProvider) -> ProtectedView) {
    self.userWallet = userWallet
    self.label = label
    self.content = content
  }
  
  var body: some View {
    
    Button(action: { self.showSheet = true },label:label)
      .sheet(isPresented: $showSheet,content: {
        switch(self.walletProvider) {
        case .some(let walletProvider):
          content(walletProvider)
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
      )
  }
}

struct WithWalletProviderView_Previews: PreviewProvider {
  static var previews: some View {
    WithWalletProviderView(
      userWallet:UserWallet(),
      label: { Text("") },
      content: { _ in EmptyView() }
    )
  }
}
