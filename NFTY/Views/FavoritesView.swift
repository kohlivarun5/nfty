//
//  FavoritesView.swift
//  NFTY
//
//  Created by Varun Kohli on 4/23/21.
//

import SwiftUI
import BigInt

struct FavoritesView: View {
  @State private var showAddFavSheet = false
  
  typealias FavoritesDict = [String : [String : NFTWithLazyPrice?]]
  @State private var favorites : FavoritesDict = [:]
  
  @State private var showSorted = false
  @State private var filterZeros = false
  @State private var selectedTokenId: UInt? = nil
  @State private var isLoading = true
  
  func dictToNfts(_ dict : FavoritesDict) -> [NFTWithLazyPrice] {
    var res : [NFTWithLazyPrice] = [];
    self.favorites.forEach { address,tokens in
      tokens.values.forEach {
        $0.map { res.append($0) }
      }
    }
    return res.sorted(by: { $0.nft.id < $1.nft.id });
  }
  
  func updateFavorites(_ dict:[String : [String : Bool]]) -> Void {
    if (dict.isEmpty) {
      self.isLoading = false
    }
    dict.forEach { address,tokens in
      tokens.forEach { tokenId,isFav in
        
        // Check if already handled
        switch(self.favorites[address]) {
        case .some(let tokens):
          switch (tokens[tokenId]) {
          case .some(let wasFav):
            if (isFav == (wasFav != nil)) {
              ()
            }
          case .none:
            self.favorites[address]!.updateValue(nil,forKey:tokenId)
          }
        case .none:
          self.favorites.updateValue([:], forKey:address)
        }
        
        if (isFav) {
          collectionsFactory.getByAddress(address)!.data.contract.getToken(UInt(tokenId)!)
            .done(on:.main) { nft in
              self.favorites[address]!.updateValue(nft,forKey:tokenId)
              self.isLoading = false // **** Update isLoading when we add to the list
            }.catch { print($0) }
        } else {
          self.favorites[address]!.updateValue(nil,forKey:tokenId)
          self.isLoading = false // **** Update isLoading when we add to the list
        }
      }
    }
  }
  
  struct FillAll: View {
    let color: Color
    
    var body: some View {
      GeometryReader { proxy in
        self.color.frame(width: proxy.size.width * 1.3).fixedSize()
      }
    }
  }
  var body: some View {
    
    VStack {
      switch (isLoading) {
      case true:
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle())
          .scaleEffect(3,anchor: .center)
          .padding()
      case false:
        let nfts = dictToNfts(self.favorites);
        switch(nfts.count) {
        case 0:
          Text("No Favorites Added")
            .font(.title)
            .foregroundColor(.secondary)
        case _:
          ScrollView {
            LazyVStack(pinnedViews:[.sectionHeaders]){
              ForEach(nfts,id:\.id) { nft in
                let info = collectionsFactory.getByAddress(nft.nft.address)!.info;
                let samples = [info.url1,info.url2,info.url3,info.url4];
                ZStack {
                  RoundedImage(
                    nft:nft.nft,
                    price:.lazy(nft.indicativePriceWei),
                    samples:samples,
                    themeColor:info.themeColor,
                    width: .normal
                  )
                  .padding()
                  .onTapGesture {
                    //perform some tasks if needed before opening Destination view
                    self.selectedTokenId = nft.nft.tokenId
                  }
                  NavigationLink(destination: NftDetail(
                    nft:nft.nft,
                    price:.lazy(nft.indicativePriceWei),
                    samples:samples,
                    themeColor:info.themeColor,
                    themeLabelColor:info.themeLabelColor,
                    similarTokens:info.similarTokens
                  ),tag:nft.nft.tokenId,selection:$selectedTokenId) {}
                  .hidden()
                }
              }
            }
            .animation(.default)
          }
        }
      }
    }
    .toolbar {
      Button(action: {
        self.showAddFavSheet = true
      }) {
        Image(systemName:"plus.circle.fill")
      }
    }
    .sheet(isPresented: $showAddFavSheet,onDismiss: {
      let favorites = UserDefaults.standard.object(forKey: UserDefaultsKeys.favoritesDict.rawValue) as? [String : [String : Bool]]
      updateFavorites(favorites ?? [:])
    }) {
      AddFavSheet()
    }
    .onAppear {
      let favorites = UserDefaults.standard.object(forKey: UserDefaultsKeys.favoritesDict.rawValue) as? [String : [String : Bool]]
      updateFavorites(favorites ?? [:])
    }
  }
}
struct FavoritesView_Previews: PreviewProvider {
  static var previews: some View {
    FavoritesView()
  }
}
