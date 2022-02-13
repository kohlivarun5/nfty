//
//  TokenListView.swift
//  NFTY
//
//  Created by Varun Kohli on 7/24/21.
//

import SwiftUI
import Web3

struct TokenListView: View {
  
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  
  let collection : Collection
  
  @ObservedObject var nfts : NftTokenList
  @State private var selectedTokenId: UInt? = nil
  
  init(collection:Collection,tokenIds:[UInt]) {
    self.collection = collection
    self.nfts = NftTokenList(contract:collection.contract,tokenIds:tokenIds)
    self.nfts.loadMore { }
  }
  
  var body: some View {
    GeometryReader { metrics in
      ScrollView {
        LazyVGrid(
          columns: Array(
            repeating:GridItem(.flexible()),
            count: metrics.size.width > RoundedImage.NormalSize * 4 ? 3 : metrics.size.width > RoundedImage.NormalSize * 3 ? 2 : 1),
          pinnedViews: [.sectionHeaders])
        {
          ForEach(nfts.tokens.indices,id:\.self) { index in
            let nft = nfts.tokens[index];
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
                collection:collection,
                hideOwnerLink:false,
                selectedProperties:[]
              ),tag:nft.nft.tokenId,selection:$selectedTokenId) {}
              .hidden()
            }
            .onAppear {
              DispatchQueue.global(qos:.userInitiated).async {
                self.nfts.next(currentIndex: index)
              }
            }
          }
        }
      }
    }
  }
}

struct TokenListView_Previews: PreviewProvider {
  static var previews: some View {
    TokenListView(collection:SampleCollection,tokenIds:[])
  }
}
