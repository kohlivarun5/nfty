//
//  TokensByPropertiesList.swift
//  NFTY
//
//  Created by Varun Kohli on 8/29/21.
//

import SwiftUI

struct TokensByPropertiesList: View {
  
  let properties : [SimilarTokensGetter.TokenAttributePercentile]
  let collection : Collection
  
  @ObservedObject var nfts : TokensByPropertiesObject
  @State private var selectedTokenId: UInt? = nil
  
  private func title(_ selectedProperties : [(name:String,value:String)]) -> String {
    switch(nfts.selectedProperties.count) {
    case 1:
      return "\(nfts.selectedProperties[0].name.capitalized): \(nfts.selectedProperties[0].value.capitalized)"
    default:
      return ""//Filtered"//\((collection.info.similarTokens?.label.map { " \($0)" }) ?? "")"
    }
    
  }
  
  var body: some View {
    VStack(spacing:0) {
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
        
        TokenPropertiesGrid(properties: properties,collection:collection,selectedProperties:self.nfts.selectedProperties)
          .frame(maxHeight:135)
          .padding([.leading,.trailing])
      }
    }
    .navigationBarTitle(collection.info.name,displayMode: .inline)
  }
}
