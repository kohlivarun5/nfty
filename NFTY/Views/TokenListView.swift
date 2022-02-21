//
//  TokenListView.swift
//  NFTY
//
//  Created by Varun Kohli on 7/24/21.
//

import SwiftUI
import Web3

struct TokenListView: View {
  
  let collection : Collection
  @StateObject var nfts : NftTokenList
  
  @State private var selectedTokenId: NFT.NftID? = nil
  
  var body: some View {
    GeometryReader { metrics in
      ScrollView {
        LazyVGrid(
          columns: Array(
            repeating:GridItem(.flexible(maximum:RoundedImage.NormalSize+80)),
            count: metrics.size.width > RoundedImage.NormalSize * 4 ? 3 : metrics.size.width > RoundedImage.NormalSize * 3 ? 2 : 1),
          pinnedViews: [.sectionHeaders])
        {
          ForEach(nfts.tokens.indices,id:\.self) { index in
            let nft = nfts.tokens[index];
            ZStack {
              RoundedImage(
                nft:nft.nft,
                price:.lazy(nft.indicativePrice),
                collection:collection,
                width: .normal,
                resolution: .normal
              )
                .shadow(color:.accentColor,radius:0)
                .padding()
                .onTapGesture { self.selectedTokenId = nft.nft.id }
              NavigationLink(destination: NftDetail(
                nft:nft.nft,
                price:.lazy(nft.indicativePrice),
                collection:collection,
                hideOwnerLink:false,
                selectedProperties:[]
              ),tag:nft.nft.id,selection:$selectedTokenId) {}
              .hidden()
            }
            .onAppear {
              DispatchQueue.global(qos:.userInitiated).async {
                self.nfts.next(currentIndex: index)
              }
            }
          }
        }.onAppear {self.nfts.loadMore {}}
      }
    }
  }
}
