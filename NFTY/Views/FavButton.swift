//
//  FavButton.swift
//  NFTY
//
//  Created by Varun Kohli on 4/25/21.
//

import SwiftUI
import Firebase

struct FavButton: View {
  private var firebase = FirebaseDb()
  @State private var isFavorite : Bool = false
  
  enum Size {
    case large
    case medium
  }
  var nft : NFT
  var size : Size
  
  init(nft:NFT,size:Size) {
    self.nft = nft
    self.size = size
  }
  
  private func fontOfSize(_ size:Size) -> Font {
    switch(self.size) {
      case .large:
        return .largeTitle
      case .medium:
        return .title
    }
  }
  
  var body: some View {
    Image(systemName: self.isFavorite ? "heart.fill" : "heart")
      .foregroundColor(self.isFavorite ? .red : .black)
      .font(fontOfSize(self.size))
      .frame(width: 44, height: 44)
      .onTapGesture(count:self.isFavorite ? 2 : 1) {
        firebase.addFavorite(address: nft.address, tokenId: nft.tokenId,isFavorite:!self.isFavorite);
      }
      .padding()
      .onAppear {
        firebase.observeFavorite(address:nft.address,tokenId:nft.tokenId) { [self] data in
          self.isFavorite = data.value as? Bool ?? false
        }
      }
  }
}

struct FavButton_Previews: PreviewProvider {
  static var previews: some View {
    FavButton(nft: CryptoPunksNfts[0],size:.large)
  }
}
