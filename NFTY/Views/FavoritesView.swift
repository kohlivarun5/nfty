//
//  FavoritesView.swift
//  NFTY
//
//  Created by Varun Kohli on 4/23/21.
//

import SwiftUI
import PromiseKit

struct FavoritesView: View {
  
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  
  private var firebase = FirebaseDb()
   
  typealias FavoritesDict = [String : [String : NFT?]]
  @State private var favorites : FavoritesDict = [:]
  
  @State private var showSorted = false
  @State private var filterZeros = false
  @State private var selectedTokenId: UInt? = nil
  
  func dictToNfts(_ dict : FavoritesDict) -> [NFT] {
    var res : [NFT] = [];
    self.favorites.forEach { address,tokens in
      tokens.values.forEach {
        $0.map { res.append($0) }
      }
    }
    return res;
  }
  
  
  func sorted(_ l:[NFT]) -> [NFT] {
    showSorted ? l.sorted(by:{$0.eth < $1.eth}) : l
  }
  func filtered(_ l:[NFT]) -> [NFT] {
    filterZeros ? l.filter({$0.eth != 0}) : l
  }
  
  func updateFavorites(_ dict:[String : [String : Bool]]) -> Void {
    // print(dict);
    dict.forEach { address,tokens in
      tokens.forEach { tokenId,isFav in
        if (isFav) {
          firstly {
            collectionsFactory.getByAddress(address)!.data.contract.getToken(UInt(tokenId)!)
          }.done { nft in
            switch (self.favorites[address]) {
              case .none:
                self.favorites.updateValue([:], forKey:address)
              default:
                ()
            }
            self.favorites[address]!.updateValue(nft,forKey:tokenId)
          }
        } else {
          switch (self.favorites[address]) {
            case .none:
              self.favorites.updateValue([:], forKey:address)
            default:
              ()
          }
          self.favorites[address]!.updateValue(nil,forKey:tokenId)
        }
        //self.favorites.append(NFT(address:address,tokenId: UInt(tokenId)!,name:"CryptoPunks",url:URL(string:"URL")!,eth:0))
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
    
    ScrollView {
      LazyVStack(pinnedViews:[.sectionHeaders]){
        Section(/*header:
                  ZStack {
                    
                    VisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
                      .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                      HStack {
                        Text("Address")
                        Spacer()
                        Text(walletAddress)
                      }
                      .padding()
                    }
                  } */
        ) {
          
          let data = sorted(filtered(dictToNfts(self.favorites)));
          ForEach(data.indices,id: \.self) { index in
            let nft = data[index];
            let info = collectionsFactory.getByAddress(nft.address)!.info;
            let samples = [info.url1,info.url2,info.url3,info.url4];
            ZStack {
              RoundedImage(nft:nft,samples:samples,themeColor:info.themeColor)
                .padding()
                .onTapGesture {
                  //perform some tasks if needed before opening Destination view
                  self.selectedTokenId = nft.tokenId
                }
              NavigationLink(destination: NftDetail(nft:nft,samples:samples,themeColor:info.themeColor),tag:nft.tokenId,selection:$selectedTokenId) {}
                .hidden()
            }
          }
        }.textCase(nil)
      }
    }
    .onAppear {
      firebase.observeUserFavorites {
        updateFavorites($0.value as? [String : [String : Bool]] ?? [:])
      }
    }
  }
}
struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
      FavoritesView()
    }
}
