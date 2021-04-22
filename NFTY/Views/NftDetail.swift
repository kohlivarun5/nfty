//
//  NftDetail.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI
import URLImage

struct NftDetail: View {
  var nft:NFT
  var samples:[String]
  var themeColor : Color
  var body: some View {
    
    VStack {
      VStack {
        NftImage(url:nft.url,samples:samples,themeColor:themeColor)
        .padding()
      }
      .background(themeColor)
      
      HStack() {
        VStack(alignment:.leading) {
          Text(nft.name)
            .font(.headline)
          Text("#\(nft.tokenId)")
            .font(.subheadline)
        }
        Spacer()
        UsdText(eth:nft.eth)
          .font(.title)
      }
      .padding()

      Spacer()
    }
    .ignoresSafeArea(edges: .top)
  }
}

struct NftDetail_Previews: PreviewProvider {
  static var previews: some View {
    NftDetail(nft:CrypotPunksNfts[0],samples:SAMPLE_PUNKS,themeColor:CryptoPunksCollection.info.themeColor)
  }
}
