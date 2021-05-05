//
//  FeedView.swift
//  NFTY
//
//  Created by Varun Kohli on 5/3/21.
//

import SwiftUI
import BigInt

// https://prafullkumar77.medium.com/how-to-making-pure-swiftui-pull-to-refresh-b497d3639ee5
struct RefreshControl: View {
  var coordinateSpace: CoordinateSpace
  var onRefresh: ()->Void
  @State var refresh: Bool = false
  var body: some View {
    GeometryReader { geo in
      if (geo.frame(in: coordinateSpace).midY > 50) {
        Spacer()
          .onAppear {
            if refresh == false {
              onRefresh() ///call refresh once if pulled more than 50px
            }
            refresh = true
          }
      } else if (geo.frame(in: coordinateSpace).maxY < 1) {
        Spacer()
          .onAppear {
            refresh = false
            ///reset  refresh if view shrink back
          }
      }
      ZStack(alignment: .center) {
        if refresh { ///show loading if refresh called
          ProgressView()
        } else { ///mimic static progress bar with filled bar to the drag percentage
          ForEach(0..<8) { tick in
            VStack {
              Rectangle()
                .fill(Color(UIColor.tertiaryLabel))
                .opacity((Int((geo.frame(in: coordinateSpace).midY)/7) < tick) ? 0 : 1)
                .frame(width: 3, height: 7)
                .cornerRadius(3)
              Spacer()
            }.rotationEffect(Angle.degrees(Double(tick)/(8) * 360))
          }.frame(width: 20, height: 20, alignment: .center)
        }
      }.frame(width: geo.size.width)
    }.padding(.top, -50)
  }
}

struct FeedView: View {
  
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  
  @ObservedObject var trades : CompositeRecentTradesObject
  
  @State private var showSorted = false
  @State private var filterZeros = true
  @State private var selectedNumber = 0
  
  @State private var action: String? = ""
  @State private var isLoading = true
  
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
    
    VStack {
      switch(isLoading) {
      case true:
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle())
          .scaleEffect(3,anchor: .center)
          .padding()
      case false:
        ScrollView {
          RefreshControl(coordinateSpace: .named("RefreshControl")) {
            self.trades.loadLatest() {
              print("Done refresh")
            }
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
