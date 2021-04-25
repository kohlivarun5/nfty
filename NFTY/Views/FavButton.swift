//
//  FavButton.swift
//  NFTY
//
//  Created by Varun Kohli on 4/25/21.
//

import SwiftUI
import Firebase

struct FavButton: View {
  
  var isFavorite : Bool
  var nft : NFT
  var firebase : FirebaseDb
  
  var body: some View {
    Image(systemName: self.isFavorite ? "heart.fill" : "heart")
      .foregroundColor(self.isFavorite ? .red : .secondary)
      .font(.largeTitle)
      .frame(width: 44, height: 44)
      .padding()
      .onTapGesture(count:self.isFavorite ? 2 : 1) {
        firebase.addFavorite(address: nft.address, tokenId: nft.tokenId,isFavorite:!self.isFavorite);
      }
    
  }
}

struct FavButton_Previews: PreviewProvider {
  static var previews: some View {
    FavButton(isFavorite:false, nft: CryptoPunksNfts[0],firebase:FirebaseDb())
  }
}
