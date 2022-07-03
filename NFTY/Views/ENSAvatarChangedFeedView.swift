//
//  ENSAvatarChangedFeedView.swift
//  NFTY
//
//  Created by Varun Kohli on 7/3/22.
//

import SwiftUI
import Web3

struct ENSAvatarChangedFeedView: View {
  @StateObject var events : ENSTextChangedViewModel
  @State private var action: NFT.NftID? = nil
  
  @State private var isInitialized : Bool = false
  
  enum RefreshButton {
    case hidden
    case loading
    case loaded
  }
  @State private var refreshButton : RefreshButton = .hidden
  
  private func triggerRefresh() {
    self.refreshButton = .loading
    self.events.loadLatest() {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.refreshButton = .loaded }
      
      // trigger refresh again after 30 seconds
      // DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 30) { self.triggerRefresh() }
    }
  }
  
  
  var body: some View {
    
    switch(self.isInitialized,self.events.loadMoreState,self.events.loadRecentState) {
    case (false,_,_),(true,.uninitialized,.uninitialized):
      VStack {
        Spacer()
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle())
          .scaleEffect(2.0, anchor: .center)
          .onAppear {
            self.events.getRecentEvents(currentIndex: 0) {
              DispatchQueue.main.async {
                print("Done isinitialized")
                self.refreshButton = .loaded
                self.isInitialized = true
                // DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 30) { self.triggerRefresh() }
              }
            }
          }
        Spacer()
        switch (self.events.loadMoreState) {
        case .uninitialized,.notLoading:
          EmptyView()
        case .loading(let progress):
          ProgressView(value: Double(progress.current), total:Double(progress.total))
            .animation(.linear, value: self.events.loadMoreState)
        }
      }
    case (true,let loadMoreState,let loadRecentState):
      
      switch (loadRecentState) {
      case .uninitialized,.notLoading:
        EmptyView()
      case .loading(let progress):
        ProgressView(value: Double(progress.current), total:Double(progress.total))
          .animation(.linear, value: self.events.loadRecentState)
      }
      
      switch(self.events.recentEvents.isEmpty) {
      case true:
        VStack {
          Spacer()
          Text("No Recent events")
            .font(.title)
            .foregroundColor(.secondary)
            .onAppear {
              self.events.loadMore {
                DispatchQueue.main.async {
                  print("Done isinitialized")
                  self.refreshButton = .loaded
                  // DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 30) { self.triggerRefresh() }
                }
              }
            }
          Spacer()
        }
      case false:
        
        GeometryReader { metrics in
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
              ForEachWithIndex(self.events.recentEvents,id:\.self.nft.nft.id) { index,item in
                ZStack {
                  
                  RoundedImage(
                    nft:item.nft.nft,
                    price:TokenPriceType.eager(NFTPriceInfo(price: nil, blockNumber: .some(.ethereum(item.blockNumber)), type: .minted)),
                    collection:item.nft.collection,
                    width: .normal,
                    resolution: .normal,
                    action:nil
                  )
                  .shadow(color:.accentColor,radius:0) //radius:item.isNew ? 10 : 0)
                  .padding()
                  .onTapGesture {
                    //perform some tasks if needed before opening Destination view
                    self.action = item.nft.nft.id
                  }
                  
                  NavigationLink(destination: NftDetail(
                    nft:item.nft.nft,
                    price:TokenPriceType.eager(NFTPriceInfo(price: nil, blockNumber: .some(.ethereum(item.blockNumber)), type: .minted)),
                    collection:item.nft.collection,
                    hideOwnerLink:false,selectedProperties:[]
                  ),tag:item.nft.nft.id,selection:$action) {}
                    .hidden()
                }.onAppear {
                  DispatchQueue.global(qos:.userInitiated).async {
                    self.events.getRecentEvents(currentIndex:index) {}
                  }
                }
              }
              .textCase(nil)
            }
          }.coordinateSpace(name: "RefreshControl")
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
      
      switch (loadMoreState) {
      case .uninitialized,.notLoading:
        EmptyView()
      case .loading(let progress):
        ProgressView(value: Double(progress.current), total:Double(progress.total))
          .animation(.linear, value: self.events.loadMoreState)
      }
    }
  }
}
