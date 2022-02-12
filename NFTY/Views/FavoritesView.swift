//
//  FavoritesView.swift
//  NFTY
//
//  Created by Varun Kohli on 4/23/21.
//

import SwiftUI
import BigInt
import Web3
import PromiseKit

struct FavoritesView: View {
  
  @State private var showAddFavSheet = false
  
  typealias FavoritesDict = [String : (Collection,[String : NFTWithLazyPrice])]
  @State private var favorites : FavoritesDict = [:]
  
  @State private var showSorted = false
  @State private var filterZeros = false
  @State private var selectedTokenId: UInt? = nil
  @State private var isLoading = true
  
  func updateFavorites(_ dict:[String : [String : Bool]]) -> Void {
    
    if (dict.isEmpty) {
      self.isLoading = false
    }
    
    dict.reduce(Promise.value(()), { accu,dict_item in
      let (address_in,tokens) = dict_item
      return accu.then { () -> Promise<Void> in
        
        return collectionsFactory.getByAddress(address_in).then(on:.main) { collection -> Promise<Void> in
          let address = collection.contract.contractAddressHex
          return tokens.reduce(accu, { accu,token_item in
            let (tokenId,isFav) = token_item
            return accu.map { () -> Void in
              
              switch(self.favorites[address],isFav) {
              case (.some(let (collection,token_items)),true):
                // In collection and fav, add if not already there
                if (token_items[tokenId] == nil) {
                  self.favorites[address]!.1[tokenId] = collection.contract.getToken(UInt(tokenId)!)
                  self.isLoading = false // **** Update isLoading when we add to the list
                }
              case (.some(let (_,token_items)),false):
                if (token_items[tokenId] != nil) {
                  self.favorites[address]!.1.removeValue(forKey:tokenId)
                  if (token_items.isEmpty) {
                    self.favorites.removeValue(forKey: address)
                  }
                  self.isLoading = false // **** Update isLoading when we add to the list
                }
              case (.none,true):
                
                let nft = collection.contract.getToken(UInt(tokenId)!)
                self.favorites[address] = (collection,[tokenId:nft])
                self.isLoading = false // **** Update isLoading when we add to the list
              case (.none,false):
                ()
              }
            }
          })
        }.recover { error -> Promise<Void> in
          print(error);
          return Promise.value(())
        }
      }
    })
      .done(on:.main) {
        // Cleanup reverse side
        self.favorites.forEach { address,item in
          switch(dict[address]) {
          case .none:
            self.favorites.removeValue(forKey: address)
          case .some(let tokens):
            let (_,token_items) = item
            token_items.forEach { tokenId,token in
              switch(tokens[tokenId]) {
              case .none,.some(false):
                self.favorites[address]!.1.removeValue(forKey: tokenId)
                if (token_items.isEmpty) {
                  self.favorites.removeValue(forKey: address)
                }
              case .some(true):
                ()
              }
            }
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
        switch(self.favorites.isEmpty) {
        case true:
          Text("No Favorites Added")
            .font(.title)
            .foregroundColor(.secondary)
        case false:
          ScrollView {
            
            LazyVStack(pinnedViews:[.sectionHeaders]) {
              ForEach(self.favorites.map { ($0.key,$0.value) }.sorted(by: { $0.0 < $1.0 }),id:\.0) { key_value in
                let (collection,tokens) = key_value.1;
                Section(header: WalletTokensCollectionHeader(collection:collection)) {
                  
                  ForEach(tokens.map { ($0.key,$0.value)}.sorted(by: { $0.0 < $1.0 }),id:\.0) { token_info in
                    let nft = token_info.1;
                    
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
                      NavigationLink(destination: NftDetail(
                        nft:nft.nft,
                        price:.lazy(nft.indicativePriceWei),
                        collection:collection,
                        hideOwnerLink:false,selectedProperties:[]
                      ),tag:nft.nft.tokenId,selection:$selectedTokenId) {}
                      .hidden()
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
                                  self.favorites[nft.id.address]?.1.updateValue(
                                    NFTWithLazyPrice(nft:nft.nft,getPrice: {
                                      return ObservablePromise<NFTPriceStatus>(
                                        resolved: NFTPriceStatus.known(
                                          NFTPriceInfo(
                                            price: ask.wei,
                                            blockNumber: nil,
                                            type: TradeEventType.ask))
                                      )
                                    }),forKey:String(nft.id.tokenId))
                                }
                              }
                            }
                            .catch { print($0) }
                          }
                      }
                    }
                  }
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
