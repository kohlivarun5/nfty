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
    self.nft = collection.data.contract.getToken(tokenId)
  }
  
  var body: some View {
    TokenTradeView(
      nft: nft.nft,
      price: .lazy(nft.indicativePriceWei),
      collection:collection,
      size: .medium,
      userWallet: userWallet,
      isSheet: true)
  }
}

struct NftTradeUrlView_Previews: PreviewProvider {
    static var previews: some View {
        NftTradeUrlView(collection:SampleCollection,tokenId: SampleToken.tokenId,userWallet: UserWallet())
    }
}
