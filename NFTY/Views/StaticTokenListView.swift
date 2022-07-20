//
//  StaticTokenListView.swift
//  NFTY
//
//  Created by Varun Kohli on 8/9/21.
//

import SwiftUI
import BigInt

struct StaticTokenListView: View {
  
  @State var tokens : [NFTToken]
  @State private var selectedTokenId: BigUInt? = nil
  
  var body: some View {
    GeometryReader { metrics in
      ScrollView {
        LazyVGrid(
          columns: RoundedImage.columnsLargeIcons(width: metrics.size.width),
          pinnedViews: [.sectionHeaders])
        {
          ForEach(tokens) { token in
            let nft = token.nft;
            let collection = token.collection;
            
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
                .onTapGesture { self.selectedTokenId = nft.nft.tokenId }
              NavigationLink(destination: NftDetail(
                nft:nft.nft,
                price:.lazy(nft.indicativePrice),
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
}

struct StaticTokenListView_Previews: PreviewProvider {
  static var previews: some View {
    StaticTokenListView(tokens:[])
  }
}
