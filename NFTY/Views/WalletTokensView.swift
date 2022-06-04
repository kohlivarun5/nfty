//
//  WalletTokensView.swift
//  NFTY
//
//  Created by Varun Kohli on 5/9/21.
//

import SwiftUI

import BigInt
import Web3

struct WalletTokensView: View {
  
  @EnvironmentObject var userWallet: UserWallet
  
  @ObservedObject var tokens : NftOwnerTokens
  
  @State private var selectedToken: NFTTokenEquatable? = nil
  
  var body: some View {
    WalletTokensSelector(tokens: tokens, enableNavLinks: true,selectedToken:$selectedToken)
      .sheet(item: $selectedToken, onDismiss: { self.selectedToken = nil }) { selected in
        TokenTradeView(
          nft: selected.token.nft.nft,
          price:.lazy(selected.token.nft.indicativePrice),
          collection:selected.token.collection,
          userWallet:userWallet,
          isSheet:true)
        .ignoresSafeArea(edges:.bottom)
        .themeStyle()
      }
  }
}
