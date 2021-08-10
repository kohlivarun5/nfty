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
    HStack {
      Spacer()
        .frame(maxWidth:20)
      
      ScrollView(.horizontal) {
        LazyHStack {
          ForEach(nfts.indices,id: \.self) { index in
            let nft = nfts[index];
            let samples = [info.url1,info.url2,info.url3,info.url4];
            ZStack {
              RoundedImage(
                nft:nft.nft,
                price:.lazy(nft.indicativePriceWei),
                samples:samples,
                themeColor:info.subThemeColor,
                themeLabelColor:info.themeLabelColor,
                rarityRank: info.rarityRanking,
                width: .narrow
              )
              //.scaleEffect(0.9)
              .onTapGesture {
                //perform some tasks if needed before opening Destination view
                self.action = String(nft.nft.tokenId)
              }
              
              NavigationLink(destination: NftDetail(
                nft:nft.nft,
                price:.lazy(nft.indicativePriceWei),
                samples:samples,
                themeColor:info.themeColor,
                themeLabelColor:info.themeLabelColor,
                similarTokens:info.similarTokens,
                rarityRank:info.rarityRanking,
                hideOwnerLink:false
              ),tag:String(nft.nft.tokenId),selection:$action) {}
              .hidden()
            }
          }
        }
      }
      Spacer()
        .frame(maxWidth:20)
    }.onAppear {
      DispatchQueue.global(qos:.userInteractive).async {
        tokens.forEach { tokenId in
          let nft = collectionsFactory.getByAddress(info.address)!.data.contract.getToken(tokenId)
          nfts.append(nft)
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
