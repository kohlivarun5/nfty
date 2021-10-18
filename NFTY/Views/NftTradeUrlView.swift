//
//  NftTradeUrlView.swift
//  NFTY
//
//  Created by Varun Kohli on 10/17/21.
//

import SwiftUI

struct NftTradeUrlView: View {
  let nft : NFTWithLazyPrice
  
  let info : CollectionInfo
  let userWallet : UserWallet
  
  init(address:String, tokenId:UInt,userWallet:UserWallet) {
    self.userWallet = userWallet
    self.nft = collectionsFactory.getByAddress(address)!.data.contract.getToken(tokenId)
    self.info = collectionsFactory.getByAddress(nft.nft.address)!.info
  }
  
  var body: some View {
    TokenTradeView(
      nft: nft.nft,
      price: .lazy(nft.indicativePriceWei),
      sample: info.sample,
      themeColor: info.themeColor,
      themeLabelColor: info.themeLabelColor,
      size: .medium,
      rarityRank: info.rarityRanking,
      userWallet: userWallet,
      isSheet: true)
  }
}

struct NftTradeUrlView_Previews: PreviewProvider {
    static var previews: some View {
        NftTradeUrlView(address:SampleToken.address,tokenId: SampleToken.tokenId,userWallet: UserWallet())
    }
}
