//
//  CollectionRecentView.swift
//  NFTY
//
//  Created by Varun Kohli on 2/19/22.
//

import SwiftUI

struct CollectionRecentView: View {
  private let collection : Collection
  private let info : CollectionInfo
  
  @ObservedObject var recentTrades : NftRecentTradesObject
  
  @State private var action: String? = ""
  
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
  
  init(loader:CompositeRecentTradesObject.CollectionLoader) {
    self.collection = loader.collection;
    self.info = collection.info;
    self.recentTrades = loader.recentTrades;
  }
  
  var body: some View {
    GeometryReader { metrics in
      ScrollView {
        LazyVGrid(
          columns: Array(
            repeating:GridItem(.flexible(maximum:RoundedImage.NormalSize+80)),
            count: metrics.size.width > RoundedImage.NormalSize * 4 ? 3 : metrics.size.width > RoundedImage.NormalSize * 3 ? 2 : 1),
          pinnedViews: [.sectionHeaders])
        {
          let data = sorted(recentTrades.recentTrades);
          ForEach(data.indices,id: \.self) { index in
            let nft = data[index];
            ZStack {
              RoundedImage(
                nft:nft.nft,
                price:nft.indicativePriceWei,
                collection:collection,
                width: .normal,
                resolution: .normal
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
                collection:collection,
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
    }
    .onAppear {
      self.recentTrades.getRecentTrades(currentIndex: nil) {}
    }
  }
}

struct CollectionRecentView_Previews: PreviewProvider {
  static var previews: some View {
    CollectionRecentView(loader:CompositeCollection.loaders[0])
  }
}
