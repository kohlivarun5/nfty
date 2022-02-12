//
//  FavButton.swift
//  NFTY
//
//  Created by Varun Kohli on 4/25/21.
//

import SwiftUI

struct FavButton: View {
  @State private var isFavorite : Bool = false
   
  enum Size {
    case large
    case medium
  }
  let nft : NFT
  let size : Size
  let color : Color
  
  init(nft:NFT,size:Size,color:Color) {
    self.nft = nft
    self.size = size
    self.color = color
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
      .foregroundColor(self.isFavorite ? .red : self.color)
      .font(fontOfSize(self.size))
      .frame(width: 44, height: 44)
      .onTapGesture(count:self.isFavorite ? 2 : 1) {
        self.isFavorite = !self.isFavorite
        switch (NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.favoritesDict.rawValue) as? [String : [String : Bool]]) {
        case .none:
          var favorites : [String : [String : Bool]] = [:]
          if (self.isFavorite) {
            favorites[nft.address] = [:]
            favorites[nft.address]![String(nft.tokenId)] = true
          }
          
          // cleanup & filter
          favorites.forEach { address,items in
            items.forEach { tokenId,isFav in
              if(!isFav) { favorites[address]!.removeValue(forKey: tokenId) }
            }
            if (favorites[address]!.isEmpty) {
              favorites.removeValue(forKey: address)
            }
          }
          
          NSUbiquitousKeyValueStore.default.set(favorites,forKey:CloudDefaultStorageKeys.favoritesDict.rawValue)
        case .some(var favorites):
          switch (favorites[nft.address]) {
          case .none:
            if (self.isFavorite) {
              favorites[nft.address] = [String(nft.tokenId):true]
            }
          case .some:
            if (self.isFavorite) {
              favorites[nft.address]![String(nft.tokenId)] = true
            } else {
              favorites[nft.address]!.removeValue(forKey: String(nft.tokenId))
            }
          }
          
          // cleanup & filter
          favorites.forEach { address,items in
            items.forEach { tokenId,isFav in
              if(!isFav) { favorites[address]!.removeValue(forKey: tokenId) }
            }
            if (favorites[address]!.isEmpty) {
              favorites.removeValue(forKey: address)
            }
          }
          
          NSUbiquitousKeyValueStore.default.set(favorites,forKey:CloudDefaultStorageKeys.favoritesDict.rawValue)
        }
        let impactMed = UIImpactFeedbackGenerator(style: .light)
        impactMed.impactOccurred()
      }
      .padding()
      .onAppear {
        let favorites = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.favoritesDict.rawValue) as? [String : [String : Bool]] ?? [:]
        self.isFavorite = favorites.reduce(false, { isFav,coll_items in
          let (address,items) = coll_items
          if (address.lowercased() != nft.address.lowercased()) {
            return isFav || false
          } else {
            return items.reduce(isFav,{ isFav,token_items in
              let (tokenId,isFavToken) = token_items
              return isFav || (tokenId == String(nft.tokenId) && isFavToken)
            })
          }
        })
      }
  }
}

struct FavButton_Previews: PreviewProvider {
  static var previews: some View {
    FavButton(nft: SampleToken,size:.large,color:.black)
  }
}
