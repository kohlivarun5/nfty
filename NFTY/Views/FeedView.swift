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
            .scaleEffect(1.5, anchor: .center)
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
  
  enum RefreshButton {
    case hidden
    case loading
    case loaded
  }
  @State private var refreshButton : RefreshButton = .hidden
  @State private var action: String? = ""
  @State private var isInitialized = false
  
  init(trades:CompositeRecentTradesObject) {
    self.trades = trades;
  }
  
  private func triggerRefresh() {
    self.refreshButton = .loading
    self.trades.loadLatest() {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.refreshButton = .loaded }
      
      // trigger refresh again after 30 seconds
      // DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 30) { self.triggerRefresh() }
    }
  }
  
  var body: some View {
    
    VStack {
      switch(isInitialized,self.trades.loadMoreState,self.trades.loadRecentState) {
      case (false,_,_),(true,.uninitialized,.uninitialized):
        VStack {
          switch (self.trades.loadMoreState) {
          case .uninitialized,.notLoading:
            EmptyView()
          case .loading(let progress):
            ProgressView(value: Double(progress.current), total:Double(progress.total))
              .animation(.linear, value: self.trades.loadRecentState)
          }
          
          ScrollView {
            LazyVStack {
              let sampleInfos = [
                CompositeCollection.loaders[0].collection.info,
                CompositeCollection.loaders[3].collection.info,
                CompositeCollection.loaders[4].collection.info,
                CompositeCollection.loaders[5].collection.info,
              ]
              
              ForEach(sampleInfos.indices,id:\.self) { index in
                let info = sampleInfos[index]
                ZStack {
                  
                  VStack {
                    ZStack {
                      
                      Image(info.sample)
                        .interpolation(.none)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                        .background(info.themeColor)
                        .blur(radius:20)
                      ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: info.themeColor))
                        .scaleEffect(2.0, anchor: .center)
                      
                    }
                    
                    HStack {
                      Spacer()
                    }
                    .font(.subheadline)
                    .padding()
                  }
                  
                  .border(Color.secondary)
                  .frame(width:250)
                  .clipShape(RoundedRectangle(cornerRadius:20, style: .continuous))
                  .overlay(
                    RoundedRectangle(cornerRadius:20, style: .continuous).stroke(Color.secondary, lineWidth: 2))
                }
                .padding()
              }
            }
            .onAppear {
              self.trades.getRecentTrades(currentIndex: 0) {
                DispatchQueue.main.async {
                  self.isInitialized = true
                  self.refreshButton = .loaded
                  // DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 30) { self.triggerRefresh() }
                }
              }
            }
          }
          
        }
      case (true,let loadMoreState,let loadRecentState):
        VStack {
          GeometryReader { metrics in
            switch (loadRecentState) {
            case .uninitialized,.notLoading:
              EmptyView()
            case .loading(let progress):
              ProgressView(value: Double(progress.current), total:Double(progress.total))
                .animation(.linear, value: self.trades.loadRecentState)
            }
            ScrollView {
              PullToRefresh(coordinateSpaceName: "RefreshControl") {
                self.triggerRefresh()
                let impactMed = UIImpactFeedbackGenerator(style: .light)
                impactMed.impactOccurred()
              }
              LazyVGrid(
                columns: Array(
                  repeating:GridItem(.flexible(maximum:RoundedImage.NormalSize+80)),
                  count: metrics.size.width > RoundedImage.NormalSize * 4 ? 3 : metrics.size.width > RoundedImage.NormalSize * 3 ? 2 : 1),
                pinnedViews: [.sectionHeaders])
              {
                ForEachWithIndex(trades.recentTrades,id:\.self.nft.id) { index,item in
                  ZStack {
                    RoundedImage(
                      nft:item.nft.nftWithPrice.nft,
                      price:item.nft.nftWithPrice.indicativePrice,
                      collection:item.collection,
                      width: .normal,
                      resolution: .normal
                    )
                    .shadow(color:.accentColor,radius:0)
                    .padding()
                    .onTapGesture {
                      //perform some tasks if needed before opening Destination view
                      self.action = "\(item.nft.nftWithPrice.nft.address):\(item.nft.nftWithPrice.nft.tokenId)"
                    }
                    
                    NavigationLink(destination: NftDetail(
                      nft:item.nft.nftWithPrice.nft,
                      price:item.nft.nftWithPrice.indicativePrice,
                      collection:item.collection,
                      hideOwnerLink:false,selectedProperties:[]
                    ),tag:"\(item.nft.nftWithPrice.nft.address):\(item.nft.nftWithPrice.nft.tokenId)",selection:$action) {}
                      .hidden()
                  }.onAppear {
                    DispatchQueue.global(qos:.userInitiated).async {
                      self.trades.getRecentTrades(currentIndex:index) {}
                    }
                  }
                }
                .textCase(nil)
              }
            }.coordinateSpace(name: "RefreshControl")
          }
          switch (loadMoreState) {
          case .uninitialized,.notLoading:
            EmptyView()
          case .loading(let progress):
            ProgressView(value: Double(progress.current), total:Double(progress.total))
              .animation(.linear, value: self.trades.loadMoreState)
          }
        }
      }
    }
    .navigationBarItems(
      trailing:
        HStack {
          switch refreshButton {
          case .hidden:
            EmptyView()
          case .loading:
            ProgressView()
          case .loaded:
            Button(action: {
              self.triggerRefresh()
              let impactMed = UIImpactFeedbackGenerator(style: .light)
              impactMed.impactOccurred()
            }) {
              Image(systemName:"arrow.clockwise.circle.fill")
                .font(.title3)
                .foregroundColor(.accentColor)
                .padding(10)
            }
          }
        }
    )
    
  }
}


struct FeedView_Previews: PreviewProvider {
  static var previews: some View {
    FeedView(trades:CompositeCollection)
  }
}
