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
  
  private var info : CollectionInfo
  
  @ObservedObject var recentTrades : NftRecentTradesObject
  
  @State private var selectedNumber = 0
  
  @State private var action: String? = ""
  
  init(collection:Collection) {
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
      switch(left.indicativePriceWei.blockNumber,right.indicativePriceWei.blockNumber) {
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
    // print(res[safe:0]);
    return res;
  }
  
  var body: some View {
    
    ScrollView {
      LazyVStack {
        let data = sorted(recentTrades.recentTrades);
        ForEach(data.indices,id: \.self) { index in
          let nft = data[index];
          let samples = [info.url1,info.url2,info.url3,info.url4];
          ZStack {
            RoundedImage(
              nft:nft.nft,
              price:.eager(nft.indicativePriceWei),
              samples:samples,
              themeColor:info.themeColor,
              themeLabelColor:info.themeLabelColor,
              rarityRank: info.rarityRank,
              width: .normal
            )
            .padding()
            .onTapGesture {
              //perform some tasks if needed before opening Destination view
              self.action = String(nft.nft.tokenId)
            }
            
            NavigationLink(destination: NftDetail(
              nft:nft.nft,
              price:.eager(nft.indicativePriceWei),
              samples:samples,
              themeColor:info.themeColor,
              themeLabelColor:info.themeLabelColor,
              similarTokens:info.similarTokens,
              rarityRank:info.rarityRank,
              hideOwnerLink:false
            ),tag:String(nft.nft.tokenId),selection:$action) {}
            .hidden()
          }.onAppear {
            self.recentTrades.getRecentTrades(currentIndex:index);
          }
        }
      }.animation(.default)
    }
    .toolbar {
        Link(destination: info.webLink) {
          Image(systemName: "safari")
        }
    }
    .navigationBarTitle(info.name)
    .navigationBarBackButtonHidden(true)
    .navigationBarItems(leading: Button(action: {presentationMode.wrappedValue.dismiss()}, label: { BackButton() }))
    .onAppear {
      self.recentTrades.getRecentTrades(currentIndex: nil)
    }
    
  }
}

struct CollectionView_Previews: PreviewProvider {
  static var previews: some View {
    CollectionView(collection:SampleCollection)
  }
}
