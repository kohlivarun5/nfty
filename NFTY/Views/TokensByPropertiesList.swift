//
//  TokensByPropertiesList.swift
//  NFTY
//
//  Created by Varun Kohli on 8/29/21.
//

import SwiftUI

struct TokensByPropertiesList: View {
  
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  
  @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
  
  let properties : [SimilarTokensGetter.TokenAttributePercentile]
  let collection : Collection
  
  @ObservedObject var nfts : TokensByPropertiesObject
  @State private var selectedTokenId: UInt? = nil
  
  var body: some View {
    VStack(spacing:0) {
      ScrollView {
        LazyVGrid(
          columns: Array(
            repeating:GridItem(.flexible(maximum:160)),
            count:horizontalSizeClass == .some(.compact) ? 2 : 3)) {
          ForEach(nfts.tokens.indices,id:\.self) { index in
            let nft = nfts.tokens[index];
            let info = collection.info
            
            ZStack {
              NftImage(
                nft:nft.nft,
                sample:info.sample,
                themeColor:info.themeColor,
                themeLabelColor:info.themeLabelColor,
                size:.small
              )
              .clipShape(RoundedRectangle(cornerRadius:20, style: .continuous))
              .shadow(color:.secondary,radius:5)
              .padding(10)
              .onTapGesture {
                //perform some tasks if needed before opening Destination view
                self.selectedTokenId = nft.nft.tokenId
              }
              NavigationLink(destination: NftDetail(
                nft:nft.nft,
                price:.lazy(nft.indicativePriceWei),
                sample:info.sample,
                themeColor:info.themeColor,
                themeLabelColor:info.themeLabelColor,
                similarTokens:info.similarTokens,
                rarityRank:info.rarityRanking,
                hideOwnerLink:false,
                selectedProperties:nfts.selectedProperties
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
      }
      
      VStack(spacing:0) {
        HStack {
          Spacer()
          Text("Filters")
            .font(.caption).italic()
            .foregroundColor(.secondaryLabel)
          Spacer()
        }
        .padding([.top,.bottom],5)
        .background(RoundedCorners(color: .secondarySystemBackground, tl: 0, tr: 0, bl: 20, br: 20))
        
        TokenPropertyFilters(nfts: nfts)
          .frame(maxHeight:135)
          .padding([.leading,.trailing])
      }
    }
    .navigationBarTitle(collection.info.name,displayMode: .inline)
    .navigationBarBackButtonHidden(true)
    .navigationBarItems(
      leading:
        Button(action: {presentationMode.wrappedValue.dismiss()},
               label: { BackButton() })
    )
  }
}
