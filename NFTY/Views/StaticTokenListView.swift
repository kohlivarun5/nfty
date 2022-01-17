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
  
  let collection : Collection
  
  var body: some View {
    ScrollView {
      LazyVStack {
        ForEach(nfts.indices,id:\.self) { index in
          let nft = nfts[index];
          
          ZStack {
            RoundedImage(
              nft:nft.nft,
              price:.lazy(nft.indicativePriceWei),
              collection:collection,
              width: .normal
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
    StaticTokenListView(nfts:[],collection:SampleCollection)
  }
}
