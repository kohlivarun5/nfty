//
//  NftDetail.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI
import URLImage

struct NftDetail: View {
  
  @State private var isFavorite : Bool = false
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  
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
          HStack(alignment:.bottom) {
            Spacer()
            VStack {
              Spacer()
              FavButton(isFavorite:self.isFavorite, nft:nft,firebase:firebase)
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
    .navigationBarBackButtonHidden(true)
    .navigationBarItems(leading: Button(action: {presentationMode.wrappedValue.dismiss()}, label: { BackButton() }))
    .ignoresSafeArea(edges: .top)
    .onAppear {
      firebase.observeFavorite(address:nft.address,tokenId:nft.tokenId) { [self] data in
        //print(data);
        self.isFavorite = data.value as? Bool ?? false
      }
    }
  }
}

struct NftDetail_Previews: PreviewProvider {
  static var previews: some View {
    NftDetail(nft:CryptoPunksNfts[0],samples:SAMPLE_PUNKS,themeColor:CryptoPunksCollection.info.themeColor)
  }
}
