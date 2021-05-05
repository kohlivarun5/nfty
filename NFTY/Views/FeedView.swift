//
//  FeedView.swift
//  NFTY
//
//  Created by Varun Kohli on 5/3/21.
//

import SwiftUI
import BigInt

// https://prafullkumar77.medium.com/how-to-making-pure-swiftui-pull-to-refresh-b497d3639ee5
// https://stackoverflow.com/a/65100922
struct PullToRefresh: View {
  
  var coordinateSpaceName: String
  var onRefresh: ()->Void
  
  @State var needRefresh: Bool = false
  
  var body: some View {
    GeometryReader { geo in
      if (geo.frame(in: .named(coordinateSpaceName)).midY > 50) {
        Spacer()
          .onAppear {
            needRefresh = true
          }
      } else if (geo.frame(in: .named(coordinateSpaceName)).maxY < 10) {
        Spacer()
          .onAppear {
            if needRefresh {
              needRefresh = false
              onRefresh()
            }
          }
      }
      HStack {
        Spacer()
        if needRefresh {
          ProgressView()
        } else {
          EmptyView()
        }
        Spacer()
      }
    }.padding(.top, -50)
  }
}

struct FeedView: View {
  
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  
  @ObservedObject var trades : CompositeRecentTradesObject
  
  @State private var action: String? = ""
  @State private var isLoading = true
  
  init(trades:CompositeRecentTradesObject) {
    self.trades = trades;
  }
  
  private func sorted(_ l:[NFTWithPriceAndInfo]) -> [NFTWithPriceAndInfo] {
    let res = l.sorted(by:{ left,right in
      switch(left.nftWithPrice.indicativePriceWei.blockNumber,right.nftWithPrice.indicativePriceWei.blockNumber) {
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
    
    VStack {
      switch(isLoading) {
      case true:
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle())
          .scaleEffect(2,anchor: .center)
          .padding()
      case false:
        ScrollView {
          PullToRefresh(coordinateSpaceName: "RefreshControl") {
            self.trades.loadLatest() { }
          }
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
        }.coordinateSpace(name: "RefreshControl")
      }
    }
    .onAppear {
      self.trades.loadMore() {
        DispatchQueue.main.async {
          self.isLoading = false
        }
      }
    }
    
  }
}


struct FeedView_Previews: PreviewProvider {
  static var previews: some View {
    FeedView(trades:CompositeCollection)
  }
}
