//
//  CollectionView.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI
import BigInt

struct VisualEffectView: UIViewRepresentable {
  var effect: UIVisualEffect?
  func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
  func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}

struct CollectionView: View {
  
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  @Environment(\.openURL) var openURL
  
  @EnvironmentObject var userWallet: UserWallet
  
  private let collection : Collection
  private let info : CollectionInfo
  
  @ObservedObject var recentTrades : NftRecentTradesObject
  
  @State private var selectedNumber = 0
  @State private var action: String? = ""
  @State private var showRarityRanking = false
  @State private var showVault = false
  
  init(collection:Collection) {
    self.collection = collection;
    self.info = collection.info;
    self.recentTrades = collection.data.recentTrades;
  }
  
  struct FillAll: View {
    let color: Color
    
    var body: some View {
      GeometryReader { proxy in
        self.color.frame(width: proxy.size.width * 1.3).fixedSize()
      }
    }
  }
  
  private func sorted(_ l:[NFTWithPrice]) -> [NFTWithPrice] {
    let res = l.sorted(by:{ left,right in
      switch(left.blockNumber,right.blockNumber) {
      case (.none,.none):
        return true
      case (.some(let l),.some(let r)):
        return l > r;
      case (.none,.some):
        return true;
      case (.some,.none):
        return false;
      }
    })
    return res;
  }
  
  var body: some View {
    
    ScrollView {
      LazyVStack {
        let data = sorted(recentTrades.recentTrades);
        ForEach(data.indices,id: \.self) { index in
          let nft = data[index];
          ZStack {
            RoundedImage(
              nft:nft.nft,
              price:nft.indicativePriceWei,
              sample:info.sample,
              themeColor:info.themeColor,
              themeLabelColor:info.themeLabelColor,
              rarityRank: info.rarityRanking,
              width: .normal
            )
              .shadow(color:.accentColor,radius:0)
              .padding()
              .onTapGesture {
                //perform some tasks if needed before opening Destination view
                self.action = String(nft.nft.tokenId)
              }
            
            NavigationLink(destination: NftDetail(
              nft:nft.nft,
              price:nft.indicativePriceWei,
              sample:info.sample,
              themeColor:info.themeColor,
              themeLabelColor:info.themeLabelColor,
              similarTokens:info.similarTokens,
              rarityRank:info.rarityRanking,
              hideOwnerLink:false,
              selectedProperties:[]
            ),tag:String(nft.nft.tokenId),selection:$action) {}
            .hidden()
          }.onAppear {
            DispatchQueue.global(qos:.userInitiated).async {
              self.recentTrades.getRecentTrades(currentIndex:index) { }
            }
          }
        }
      }
    }
    .toolbar {
      
      
      ToolbarItem(placement: .primaryAction) {
        Menu {
          
          Button(action: { openURL(self.collection.info.webLink) }) {
            Label("Website", systemImage: "safari")
          }
          
          switch(self.info.rarityRanking,
                 userWallet.signedIn
                 && userWallet.walletAddress?.hex(eip55: true) == "0xAe71923d145ec0eAEDb2CF8197A08f12525Bddf4") {
          case (.some,true):
            Button(action: { self.showRarityRanking = true }) {
              Label("Rarity Ranking", systemImage: "list.number")
            }
          default:
            EmptyView()
          }
          
          collection.data.contract.vaultContract.map { _ in
            Button(action: { self.showVault = true }) {
              Label("NFTX Vault", systemImage: "lock.rectangle.on.rectangle")
            }
          }
          
        }
        
      label: {
        Label("Options", systemImage: "filemenu.and.selection")
      }
      .background(
        
        VStack {
          
          NavigationLink(
            destination:
              TokenListView(
                collection: self.collection,
                tokenIds:self.info.rarityRanking?.sortedTokenIds ?? []
              )
              .navigationBarTitle("\(info.name) Ranking",displayMode: .inline)
              .navigationBarBackButtonHidden(true)
              .navigationBarItems(
                leading: Button(action: {presentationMode.wrappedValue.dismiss()}, label: { BackButton() })
              ),
            isActive:$showRarityRanking
          ) {
            EmptyView()
          }
          
          collection.data.contract.vaultContract.map {
            NavigationLink(
              destination:
                NFTXVaultViewLazy(
                  collection: collection,
                  vaultContract: $0),
              isActive:$showVault
            ) {
              EmptyView()
            }
          }
        }
        
      )
      }
      
    }
    .navigationBarTitle(info.name)
    .navigationBarBackButtonHidden(true)
    .navigationBarItems(
      leading:Button(action: {presentationMode.wrappedValue.dismiss()}, label: { BackButton() })
    )
    .onAppear {
      self.recentTrades.getRecentTrades(currentIndex: nil) {}
    }
    
  }
}

struct CollectionView_Previews: PreviewProvider {
  static var previews: some View {
    CollectionView(collection:SampleCollection)
  }
}
