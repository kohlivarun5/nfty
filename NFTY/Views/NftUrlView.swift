//
//  NftUrlView.swift
//  NFTY
//
//  Created by Varun Kohli on 5/25/21.
//

import SwiftUI

struct NftUrlView: View {
  
  let nft : NFTWithLazyPrice
  
  let info : CollectionInfo
  
  init(address:String, tokenId:UInt) {
    self.nft = collectionsFactory.getByAddress(address)!.data.contract.getToken(tokenId)
    self.info = collectionsFactory.getByAddress(nft.nft.address)!.info
  }
  
  var body: some View {
    NftDetail(
      nft:nft.nft,
      price:.lazy(nft.indicativePriceWei),
      sample:info.sample,
      themeColor:info.themeColor,
      themeLabelColor:info.themeLabelColor,
      similarTokens:info.similarTokens,
      rarityRank:info.rarityRanking,
      hideOwnerLink:true
    )
  }
}

struct NftUrlView_Previews: PreviewProvider {
  static var previews: some View {
    NftUrlView(address:SampleToken.address,tokenId: SampleToken.tokenId)
  }
}
