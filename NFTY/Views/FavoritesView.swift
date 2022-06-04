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
  
  typealias FavoritesDict = [String : (Collection,[String : NFTWithLazyPrice])]
  @State private var favorites : FavoritesDict = [:]
  
  @State private var showSorted = false
  @State private var filterZeros = false
  @State private var selectedTokenId: BigUInt? = nil
  @State private var isLoading = true
  
  func updateFavorites(_ dict:[String : [String : Bool]]) -> Void {
    dict.reduce(Promise<FavoritesDict>.value([:]), { favorites,dict_item in
      let (address_in,tokens) = dict_item
      return favorites.then { favorites -> Promise<FavoritesDict> in
        
        return collectionsFactory.getByAddress(address_in).map(on:.main) { collection -> FavoritesDict in
          let address = collection.contract.contractAddressHex
          return tokens.reduce(into:favorites, { favorites,token_item in
            let (tokenId,isFav) = token_item
            
            
            switch(favorites[address],isFav) {
            case (.some(let (collection,token_items)),true):
              // In collection and fav, add if not already there
              if (token_items[tokenId] == nil) {
                favorites[address]!.1[tokenId] = collection.contract.getToken(UInt(tokenId)!)
              }
            case (.some(let (_,token_items)),false):
              if (token_items[tokenId] != nil) {
                favorites[address]!.1.removeValue(forKey:tokenId)
                if (token_items.isEmpty) {
                  favorites.removeValue(forKey: address)
                }
              }
            case (.none,true):
              
              let nft = collection.contract.getToken(UInt(tokenId)!)
              favorites[address] = (collection,[tokenId:nft])
            case (.none,false):
              ()
            }
          })
        }.recover { error -> Promise<FavoritesDict> in
          print(error);
          return Promise.value(favorites)
        }
      }
    })
    .done(on:.main) {
      self.isLoading = false
      self.favorites = $0
    }
    .catch {print ($0) }
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
          GeometryReader { metrics in
            
            ScrollView {
              LazyVGrid(
                columns: Array(
                  repeating:GridItem(.flexible(maximum: UIDevice.current.userInterfaceIdiom == .pad ? RoundedImage.NormalSize+80 : min(200,(metrics.size.width - 20) / Double(2)))),
                  count:UIDevice.current.userInterfaceIdiom == .pad
                  ? Int(metrics.size.width / RoundedImage.NormalSize) - 1
                  : 2),
                pinnedViews: [.sectionHeaders])
              {
                ForEach(self.favorites.map { ($0.key,$0.value) }.sorted(by: { $0.0 < $1.0 }),id:\.0) { key_value in
                  let (collection,tokens) = key_value.1;
                  Section(
                    header:
                      WalletTokensCollectionHeader(collection:collection)
                      .onAppear {
                        DispatchQueue.global(qos:.userInteractive).async {
                          guard let asks = (collection.contract.tradeActions
                            .map { $0.getBidAsk(tokens.map { $0.value.id.tokenId },.ask) }) else { return }
                          
                          asks.done { asks in
                            DispatchQueue.main.async {
                              
                              asks.forEach {
                                let (tokenId,bidAsk) = $0
                                
                                guard let ask = bidAsk.ask else { return }
                                
                                guard let nft = self.favorites[collection.contract.contractAddressHex]?.1[String(tokenId)] else { return }
                                
                                self.favorites[collection.contract.contractAddressHex]?.1.updateValue(
                                  NFTWithLazyPrice(nft:nft.nft,getPrice: {
                                    return ObservablePromise<NFTPriceStatus>(
                                      resolved: NFTPriceStatus.known(
                                        NFTPriceInfo(
                                          price: ask.price,
                                          blockNumber: .none,
                                          type: TradeEventType.ask))
                                    )
                                  }),forKey:String(tokenId))
                                
                              }
                            }
                          }
                          .catch { print($0) }
                          
                        }
                      }
                  ) {
                    
                    ForEach(tokens.map { ($0.key,$0.value)}.sorted(by: { $0.0 < $1.0 }),id:\.0) { token_info in
                      let nft = token_info.1;
                      
                      
                      ZStack {
                        
                        if (UIDevice.current.userInterfaceIdiom == .pad) {
                          
                          RoundedImage(
                            nft:nft.nft,
                            price:.lazy(nft.indicativePrice),
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
                          
                        } else {
                          
                          NftImage(
                            nft:nft.nft,
                            sample:collection.info.sample,
                            themeColor:collection.info.themeColor,
                            themeLabelColor:collection.info.themeLabelColor,
                            size:.small,
                            resolution:.normal,
                            favButton:.none
                          )
                          .clipShape(RoundedRectangle(cornerRadius:20, style: .continuous))
                          .shadow(color:.secondary,radius:5)
                          .padding(10)
                          .onTapGesture {
                            //perform some tasks if needed before opening Destination view
                            self.selectedTokenId = nft.nft.tokenId
                          }
                          
                          VStack {
                            TokenPrice(price: TokenPriceType.lazy(nft.indicativePrice), color: .label,hideIcon:true)
                              .padding([.top,.bottom],2)
                              .padding([.leading,.trailing],20)
                              .font(.caption2)
                              .modifier(PriceOverlay())
                            Spacer()
                            HStack {
                              Spacer()
                              FavButton(nft: nft.nft, size: .medium, color: collection.info.themeLabelColor)
                            }
                          }
                          .padding(.top,11)
                          
                        }
                        
                        NavigationLink(destination: NftDetail(
                          nft:nft.nft,
                          price:.lazy(nft.indicativePrice),
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
        }
      }
      
    }
    .navigationBarItems(
      trailing:
        NavigationLink(destination: AddFavSheet()) {
          Image(systemName:"magnifyingglass.circle.fill")
            .font(.title3)
            .foregroundColor(.accentColor)
            .padding(10)
        }
    )
    .onAppear {
      if (self.isLoading) {
        let favorites = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.favoritesDict.rawValue) as? [String : [String : Bool]]
        updateFavorites(favorites ?? [:])
      }
    }
  }
}


struct FavoritesView_Previews: PreviewProvider {
  static var previews: some View {
    FavoritesView()
  }
}
