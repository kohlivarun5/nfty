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
  let samples : [String]
  
  init(address:String, tokenId:UInt) {
    self.nft = collectionsFactory.getByAddress(address)!.data.contract.getToken(tokenId)
    self.info = collectionsFactory.getByAddress(nft.nft.address)!.info
    self.samples = [info.url1,info.url2,info.url3,info.url4]
  }
  
  var body: some View {
    NftDetail(
      nft:nft.nft,
      price:.lazy(nft.indicativePriceWei),
      samples:samples,
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
