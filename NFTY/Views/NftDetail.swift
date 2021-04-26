//
//  NftDetail.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI
import URLImage

struct NftDetail: View {
  
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
   
  var nft:NFT
  var samples:[String]
  var themeColor : Color
  var similarTokens : [TokenDistance]?
  
  var body: some View {
    
    VStack {
      NftImage(nft:nft,samples:samples,themeColor:themeColor,favButtonLocation:.bottom)
      
      HStack() {
        VStack(alignment:.leading) {
          Text(nft.name)
            .font(.headline)
          Text("#\(nft.tokenId)")
            .font(.subheadline)
        }
        Spacer()
        nft.indicativePriceWei.map { wei in
          UsdText(wei:wei)
            .font(.title)
        }
      }.padding()
      similarTokens.map { tokens in
        SimilarTokensView(info:CryptoPunksCollection.info,tokens:tokens)
      }
      
      Spacer()
    }
    .navigationBarBackButtonHidden(true)
    .navigationBarItems(leading: Button(action: {presentationMode.wrappedValue.dismiss()}, label: { BackButton() }))
    .ignoresSafeArea(edges: .top)
  }
}

struct NftDetail_Previews: PreviewProvider {
  static var previews: some View {
    NftDetail(nft:CryptoPunksNfts[0],samples:SAMPLE_PUNKS,themeColor:CryptoPunksCollection.info.themeColor,similarTokens:[])
  }
}
