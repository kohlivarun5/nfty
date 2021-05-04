//
//  FeedView.swift
//  NFTY
//
//  Created by Varun Kohli on 5/3/21.
//

import SwiftUI
import BigInt

struct FeedView: View {
  
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  
  @ObservedObject var trades : CompositeRecentTradesObject
   
  @State private var action: String? = ""
  
  init(trades:CompositeRecentTradesObject) {
    self.trades = trades;
  }
  
  private func sorted(_ l:[NFTWithPriceAndInfo]) -> [NFTWithPriceAndInfo] {
    
    let res = l.sorted(by:{ left,right in
      switch(left.nftWithPrice.blockNumber,right.nftWithPrice.blockNumber) {
      case (.none,.none):
        return left.nftWithPrice.indicativePriceWei! > right.nftWithPrice.indicativePriceWei!;
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
        let sorted : [NFTWithPriceAndInfo] = sorted(trades.recentTrades);
        ForEach(sorted.indices,id:\.self) { index in
          let info = sorted[index].info
          let nft = sorted[index].nftWithPrice
          let samples = [info.url1,info.url2,info.url3,info.url4];
          ZStack {
            RoundedImage(
              nft:nft.nft,
              price:.eager(nft.indicativePriceWei),
              samples:samples,
              themeColor:info.themeColor,
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
              similarTokens:info.similarTokens
            ),tag:String(nft.nft.tokenId),selection:$action) {}
            .hidden()
          }.onAppear {
            self.trades.getRecentTrades(currentIndex:index)
          }
        }.textCase(nil)
      }.animation(.default)
    }
    .onAppear {
      self.trades.getRecentTrades(currentIndex: nil);
    }
    
  }
}


struct FeedView_Previews: PreviewProvider {
  static var previews: some View {
    FeedView(trades:CompositeCollection)
  }
}
