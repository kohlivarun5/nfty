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
      .foregroundColor(self.isFavorite ? .red : .systemBackground)
      .font(fontOfSize(self.size))
      .frame(width: 44, height: 44)
      .onTapGesture(count:self.isFavorite ? 2 : 1) {
        self.isFavorite = !self.isFavorite
        switch (UserDefaults.standard.object(forKey: UserDefaultsKeys.favoritesDict.rawValue) as? [String : [String : Bool]]) {
        case .none:
          var favorites : [String : [String : Bool]] = [:]
          favorites[nft.address] = [:]
          favorites[nft.address]![String(nft.tokenId)] = self.isFavorite
          UserDefaults.standard.set(favorites,forKey:UserDefaultsKeys.favoritesDict.rawValue)
        case .some(var favorites):
          switch (favorites[nft.address]) {
          case .none:
            favorites[nft.address] = [String(nft.tokenId):self.isFavorite]
          case .some:
            favorites[nft.address]![String(nft.tokenId)] = self.isFavorite
          }
          UserDefaults.standard.set(favorites,forKey:UserDefaultsKeys.favoritesDict.rawValue)
        }
      }
      .padding()
      .onAppear {
        let favorites = UserDefaults.standard.object(forKey: UserDefaultsKeys.favoritesDict.rawValue) as? [String : [String : Bool]]
        self.isFavorite = favorites?[nft.address]?[String(nft.tokenId)] ?? false
      }
  }
}

struct FavButton_Previews: PreviewProvider {
  static var previews: some View {
    FavButton(nft: SampleToken,size:.large)
  }
}
