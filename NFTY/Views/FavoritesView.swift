//
//  FavoritesView.swift
//  NFTY
//
//  Created by Varun Kohli on 4/23/21.
//

import SwiftUI

struct FavoritesView: View {
  
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  
  private var firebase = FirebaseDb()
   
  typealias FavoritesDict = [String : [String : Bool]]
  @State private var favorites : FavoritesDict = [:]
  
  @State private var showSorted = false
  @State private var filterZeros = false
  @State private var selectedTokenId: String? = ""
  
  func sorted(_ l:[NFT]) -> [NFT] {
    showSorted ? l.sorted(by:{$0.eth < $1.eth}) : l
  }
  func filtered(_ l:[NFT]) -> [NFT] {
    filterZeros ? l.filter({$0.eth != 0}) : l
  }
  func dictToNfts(_ dict:FavoritesDict) -> [NFT] {
    var res : [NFT] = [];
    dict.forEach { address,tokens in
      tokens.forEach { tokenId,isFav in
        res.append(NFT(address:address,tokenId: tokenId,name:"CryptoPunks",url:URL(string:"URL")!,eth:0))
      }
    }
    return res;
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
            let info = COLLECTIONS[nft.name]!.info;
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
        self.favorites = $0.value as? [String : [String : Bool]] ?? [:];
      }
    }
  }
}
struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
      FavoritesView()
    }
}
