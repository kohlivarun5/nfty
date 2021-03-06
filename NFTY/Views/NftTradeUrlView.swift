//
//  NftTradeUrlView.swift
//  NFTY
//
//  Created by Varun Kohli on 10/17/21.
//

import SwiftUI

struct NftTradeUrlView: View {
  let nft : NFTWithLazyPrice
  
  let collection : Collection
  let userWallet : UserWallet
  
  init(collection:Collection, tokenId:UInt,userWallet:UserWallet) {
    self.userWallet = userWallet
    self.collection = collection
    self.nft = collection.contract.getToken(tokenId)
  }
  
  var body: some View {
    TokenTradeView(
      nft: nft.nft,
      price: .lazy(nft.indicativePrice),
      collection:collection,
      userWallet: userWallet,
      isSheet: true)
  }
}
