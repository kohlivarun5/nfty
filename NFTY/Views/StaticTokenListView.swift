//
//  StaticTokenListView.swift
//  NFTY
//
//  Created by Varun Kohli on 8/9/21.
//

import SwiftUI

struct StaticTokenListView: View {
  
  @State var nfts : [NFTWithLazyPrice]
  @State private var selectedTokenId: UInt? = nil
  
  var body: some View {
    ScrollView {
      LazyVStack {
        ForEach(nfts.indices,id:\.self) { index in
          let nft = nfts[index];
          let info = collectionsFactory.getByAddress(nft.nft.address)!.info;
          
          ZStack {
            RoundedImage(
              nft:nft.nft,
              price:.lazy(nft.indicativePriceWei),
              sample:info.sample,
              themeColor:info.themeColor,
              themeLabelColor:info.themeLabelColor,
              rarityRank:info.rarityRanking,
              width: .normal
            )
            .padding()
            .onTapGesture { self.selectedTokenId = nft.nft.tokenId }
            NavigationLink(destination: NftDetail(
              nft:nft.nft,
              price:.lazy(nft.indicativePriceWei),
              sample:info.sample,
              themeColor:info.themeColor,
              themeLabelColor:info.themeLabelColor,
              similarTokens:info.similarTokens,
              rarityRank:info.rarityRanking,
              hideOwnerLink:false,
              selectedProperties:[]
            ),tag:nft.nft.tokenId,selection:$selectedTokenId) {}
            .hidden()
          }
        }
      }
    }
  }
}

struct StaticTokenListView_Previews: PreviewProvider {
  static var previews: some View {
    StaticTokenListView(nfts:[])
  }
}
