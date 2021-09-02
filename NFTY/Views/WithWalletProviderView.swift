//
//  WithWalletProviderView.swift
//  NFTY
//
//  Created by Varun Kohli on 8/26/21.
//

import SwiftUI

struct WithWalletProviderView<ButtonView,ProtectedView> : View where ButtonView:View, ProtectedView : View {
  
  @State private var showSheet = false
  @ObservedObject var userWallet: UserWallet
  
  private let instruction : String
  private let label : () -> ButtonView
  private let content : (WalletProvider) -> ProtectedView
  
  init(
    userWallet: UserWallet,
    instruction : String,
    @ViewBuilder label:@escaping () -> ButtonView,
    @ViewBuilder content: @escaping (WalletProvider) -> ProtectedView) {
    self.userWallet = userWallet
    self.instruction = instruction
    self.label = label
    self.content = content
  }
  
  var body: some View {
    
    Button(action: { self.showSheet = true },label:label)
      .sheet(isPresented: $showSheet,content: {
        switch(self.userWallet.walletProvider) {
        case .some(let walletProvider):
          content(walletProvider)
            // .preferredColorScheme(.dark)
            .accentColor(.orange)
         case .none:
          VStack {
            Spacer()
            Text(instruction)
              .font(.title2)
              .foregroundColor(.secondary)
            UserWalletConnectorView(userWallet:userWallet)
            Spacer()
          }
          // .preferredColorScheme(.dark)
          .accentColor(.orange)
        }
      }
      )
  }
}

struct WithWalletProviderView_Previews: PreviewProvider {
  static var previews: some View {
    WithWalletProviderView(
      userWallet:UserWallet(),
      instruction:"Sign-In",
      label: { Text("") },
      content: { _ in EmptyView() }
    )
  }
}
