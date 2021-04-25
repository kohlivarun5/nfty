//
//  NftDetail.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI
import URLImage

struct NftDetail: View {
  
  @State private var isFavorite : Bool? = nil
  
  var firebase = FirebaseDb()
  
  var nft:NFT
  var samples:[String]
  var themeColor : Color
   
  var body: some View {
    
    VStack {
      
      VStack {
        ZStack {
          NftImage(url:nft.url,samples:samples,themeColor:themeColor)
            //.padding()
          switch(self.isFavorite) {
            case .none:
              HStack {}
            case .some(let isFav):
              HStack(alignment:.bottom) {
                Spacer()
                VStack {
                  Spacer()
                  Image(systemName: isFav ? "heart.fill" : "heart")
                    .foregroundColor(.red)
                    .font(.largeTitle)
                    .frame(width: 44, height: 44)
                }
                .padding()
                .onTapGesture(count:2) {
                  firebase.addFavorite(address: nft.address, tokenId: nft.tokenId,isFavorite:!isFav);
                }
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
        UsdText(eth:nft.eth)
          .font(.title)
      }
      .padding()
      
      Spacer()
    }
    .ignoresSafeArea(edges: .top)
    .onAppear {
      firebase.observeFavorite(address:nft.address,tokenId:nft.tokenId) { [self] data in
        print(data);
        self.isFavorite = data.value as? Bool
      }
    }
  }
}

struct NftDetail_Previews: PreviewProvider {
  static var previews: some View {
    NftDetail(nft:CryptoPunksNfts[0],samples:SAMPLE_PUNKS,themeColor:CryptoPunksCollection.info.themeColor)
  }
}
