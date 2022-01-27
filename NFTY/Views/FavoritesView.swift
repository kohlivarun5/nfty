//
//  FavoritesView.swift
//  NFTY
//
//  Created by Varun Kohli on 4/23/21.
//

import SwiftUI
import BigInt
import Web3

struct FavoritesView: View {
  @State private var showAddFavSheet = false
  
  typealias FavoritesDict = [String : [String : (Collection,NFTWithLazyPrice)?]]
  @State private var favorites : FavoritesDict = [:]
  
  @State private var showSorted = false
  @State private var filterZeros = false
  @State private var selectedTokenId: UInt? = nil
  @State private var isLoading = true
  
  func dictToNfts(_ dict : FavoritesDict) -> [(Collection,NFTWithLazyPrice)] {
    var res : [(Collection,NFTWithLazyPrice)] = [];
    self.favorites.forEach { address,tokens in
      tokens.values.forEach {
        $0.map { res.append($0) }
      }
    }
    return res.sorted(by: { $0.1.nft.id < $1.1.nft.id });
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
          _ = collectionsFactory.getByAddress(address).done(on:.main) { collection in
            let nft = collection.contract.getToken(UInt(tokenId)!)
            self.favorites[address]!.updateValue((collection,nft),forKey:tokenId)
            self.isLoading = false // **** Update isLoading when we add to the list
            
          }
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
              ForEach(nfts,id:\.1.id) { token in
                let (collection,nft) = token;
                ZStack {
                  RoundedImage(
                    nft:nft.nft,
                    price:.lazy(nft.indicativePriceWei),
                    collection:collection,
                    width: .normal,
                    resolution: .normal
                  )
                    .shadow(color:.accentColor,radius:0)
                    .padding()
                    .onTapGesture {
                      //perform some tasks if needed before opening Destination view
                      self.selectedTokenId = nft.nft.tokenId
                    }
                    .onAppear {
                      DispatchQueue.global(qos:.userInteractive).async {
                        let contract = collection.contract
                        let _ = contract.tradeActions
                          .map { $0.getBidAsk(nft.id.tokenId,.ask) }
                          .map {
                            $0.done {
                              $0.ask.map { ask in
                                DispatchQueue.main.async {
                                  self.favorites[nft.id.address]!.updateValue(
                                    (collection,
                                     NFTWithLazyPrice(nft:nft.nft,getPrice: {
                                      return ObservablePromise<NFTPriceStatus>(
                                        resolved: NFTPriceStatus.known(
                                          NFTPriceInfo(
                                            price: ask.wei,
                                            blockNumber: nil,
                                            type: TradeEventType.ask))
                                      )
                                    })),forKey:String(nft.id.tokenId))
                                }
                              }
                            }
                            .catch { print($0) }
                          }
                      }
                    }
                  NavigationLink(destination: NftDetail(
                    nft:nft.nft,
                    price:.lazy(nft.indicativePriceWei),
                    collection:collection,
                    hideOwnerLink:false,selectedProperties:[]
                  ),tag:nft.nft.tokenId,selection:$selectedTokenId) {}
                  .hidden()
                }
              }
            }
          }
        }
      }
    }
    .navigationBarItems(
      trailing:
        Button(action: {
          self.showAddFavSheet = true
        }) {
          Image(systemName:"magnifyingglass.circle.fill")
            .font(.title3)
            .foregroundColor(.accentColor)
            .padding(10)
        }
    )
    .sheet(isPresented: $showAddFavSheet,onDismiss: {
      let favorites = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.favoritesDict.rawValue) as? [String : [String : Bool]]
      updateFavorites(favorites ?? [:])
    }) {
      AddFavSheet()
        .accentColor(.orange)
        .preferredColorScheme(.dark)
    }
    .onAppear {
      let favorites = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.favoritesDict.rawValue) as? [String : [String : Bool]]
      updateFavorites(favorites ?? [:])
    }
  }
}
struct FavoritesView_Previews: PreviewProvider {
  static var previews: some View {
    FavoritesView()
  }
}
