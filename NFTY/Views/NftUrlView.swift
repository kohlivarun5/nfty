//
//  NftUrlView.swift
//  NFTY
//
//  Created by Varun Kohli on 5/25/21.
//

import SwiftUI

struct NftUrlView: View {
  
  @ObservedObject private var nft : ObservablePromise<NFTWithLazyPrice>
  
  init(address:String, tokenId:UInt) {
    print(address,tokenId)
    self.nft = ObservablePromise(promise: collectionsFactory.getByAddress(address)!.data.contract.getToken(tokenId))
  }
  
  var body: some View {
    
    ObservedPromiseView(
      data: nft,
      progress: ProgressView()) { nft in
      // print(nft)
      let info = collectionsFactory.getByAddress(nft.nft.address)!.info;
      let samples = [info.url1,info.url2,info.url3,info.url4];
      NftDetail(
        nft:nft.nft,
        price:.lazy(nft.indicativePriceWei),
        samples:samples,
        themeColor:info.themeColor,
        themeLabelColor:info.themeLabelColor,
        similarTokens:info.similarTokens,
        rarityRank:info.rarityRank,
        hideOwnerLink:true
      )
    }
  }
}

struct NftUrlView_Previews: PreviewProvider {
  static var previews: some View {
    NftUrlView(address:SampleToken.address,tokenId: SampleToken.tokenId)
  }
}
