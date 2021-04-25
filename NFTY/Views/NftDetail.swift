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
  
  var body: some View {
    
    VStack {
      
      VStack {
        ZStack {
          NftImage(url:nft.url,samples:samples,themeColor:themeColor)
          //.padding()
          HStack(alignment:.bottom) {
            Spacer()
            VStack {
              Spacer()
              FavButton(nft:nft,size:.large)
            }
          }
        }
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
        nft.indicativePriceWei.map { wei in
          UsdText(wei:wei)
            .font(.title)
        }
      }
      .padding()
      
      Spacer()
    }
    .navigationBarBackButtonHidden(true)
    .navigationBarItems(leading: Button(action: {presentationMode.wrappedValue.dismiss()}, label: { BackButton() }))
    .ignoresSafeArea(edges: .top)
  }
}

struct NftDetail_Previews: PreviewProvider {
  static var previews: some View {
    NftDetail(nft:CryptoPunksNfts[0],samples:SAMPLE_PUNKS,themeColor:CryptoPunksCollection.info.themeColor)
  }
}
