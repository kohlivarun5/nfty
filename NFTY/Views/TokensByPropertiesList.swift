//
//  TokensByPropertiesList.swift
//  NFTY
//
//  Created by Varun Kohli on 8/29/21.
//

import SwiftUI

struct TokensByPropertiesList: View {
  
  let collection : Collection
  
  @ObservedObject var nfts : TokensByPropertiesObject
  let title : String
  @State private var selectedTokenId: UInt? = nil
  
  var body: some View {
    ScrollView {
      LazyVStack {
        ForEach(nfts.tokens.indices,id:\.self) { index in
          let nft = nfts.tokens[index];
          let info = collection.info
          
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
              hideOwnerLink:false
            ),tag:nft.nft.tokenId,selection:$selectedTokenId) {}
            .hidden()
          }
          .onAppear {
            DispatchQueue.global(qos:.userInitiated).async {
              self.nfts.next(currentIndex: index)
            }
          }
        }
      }.onAppear {
        nfts.loadMore {} // TODO
      }
      .navigationBarTitle(title, displayMode:.inline)
    }
  }
}
