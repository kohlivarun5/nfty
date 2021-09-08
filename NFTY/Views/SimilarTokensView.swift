//
//  SimilarTokensView.swift
//  NFTY
//
//  Created by Varun Kohli on 4/26/21.
//

import SwiftUI

struct SimilarTokensView: View {
  
  @State private var nfts : [NFTWithLazyPrice] = []
  @State private var action: String? = ""
  
  var info : CollectionInfo
  var tokens : [UInt]
  
  var body: some View {
    GeometryReader { metrics in
      ScrollView(.horizontal) {
        LazyHStack {
          ForEach(nfts.indices,id: \.self) { index in
            let nft = nfts[index];
            ZStack {
              NftImage(
                nft:nft.nft,
                sample:info.sample,
                themeColor:info.themeColor,
                themeLabelColor:info.themeLabelColor,
                size:metrics.size.height < 700 ? .xxsmall : .xsmall,
                favButton:.none
              )
              .frame(maxHeight:200)
              .clipShape(RoundedRectangle(cornerRadius:20, style: .continuous))
              .shadow(color:.secondary,radius:5)
              .padding([.top,.bottom],12)
              .padding([.leading,.trailing],8)
              //.scaleEffect(0.9)
              .onTapGesture {
                //perform some tasks if needed before opening Destination view
                self.action = String(nft.nft.tokenId)
                
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
                selectedProperties:[]
              ),tag:String(nft.nft.tokenId),selection:$action) {}
              .hidden()
            }
          }
        }
      }
      .onAppear {
        DispatchQueue.global(qos:.userInteractive).async {
          tokens.forEach { tokenId in
            let nft = collectionsFactory.getByAddress(info.address)!.data.contract.getToken(tokenId)
            nfts.append(nft)
          }
        }
      }
    }
  }
}

struct SimilarTokensView_Previews: PreviewProvider {
  static var previews: some View {
    SimilarTokensView(info:SampleCollection.info,tokens:[])
  }
}
