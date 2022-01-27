//
//  StaticTokenListView.swift
//  NFTY
//
//  Created by Varun Kohli on 8/9/21.
//

import SwiftUI

struct StaticTokenListView: View {
  
  @State var tokens : [NFTToken]
  @State private var selectedTokenId: UInt? = nil
  
  var body: some View {
    ScrollView {
      LazyVStack {
        ForEach(tokens) { token in
          let nft = token.nft;
          let collection = token.collection;
          
          ZStack {
            RoundedImage(
              nft:nft.nft,
              price:.lazy(nft.indicativePriceWei),
              collection:collection,
              width: .normal,
              resolution: .normal
            )
            .shadow(color:.accentColor,radius:0)
            .padding()
            .onTapGesture { self.selectedTokenId = nft.nft.tokenId }
            NavigationLink(destination: NftDetail(
              nft:nft.nft,
              price:.lazy(nft.indicativePriceWei),
              collection: collection,
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
    StaticTokenListView(tokens:[])
  }
}
