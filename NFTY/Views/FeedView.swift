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
  
  @State private var showSorted = false
  @State private var filterZeros = true
  @State private var selectedNumber = 0
  
  @State private var action: String? = ""
  
  init(trades:CompositeRecentTradesObject) {
    self.trades = trades;
  }
  
  var body: some View {
    
    ScrollView {
      LazyVStack {
        
        ForEach(trades.recentTrades.indices,id: \.self) { index in
          let info = trades.recentTrades[index].info
          let nft = trades.recentTrades[index].nftWithPrice
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
    .navigationBarTitle("Feed")
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
