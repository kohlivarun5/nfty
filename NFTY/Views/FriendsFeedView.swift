  //
  //  FriendsFeedView.swift
  //  NFTY
  //
  //  Created by Varun Kohli on 3/20/22.
  //

import SwiftUI
import Web3

struct FriendsFeedView: View {
  @StateObject var events : FriendsFeedViewModel
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
        
        VStack {
          
          GeometryReader { metrics in
            
            switch (loadRecentState) {
            case .uninitialized,.notLoading:
              EmptyView()
            case .loading(let progress):
              ProgressView(value: Double(progress.current), total:Double(progress.total))
                .animation(.linear, value: self.events.loadRecentState)
            }
            
            ScrollView {
              PullToRefresh(coordinateSpaceName: "RefreshControl") {
                self.triggerRefresh()
                let impactMed = UIImpactFeedbackGenerator(style: .light)
                impactMed.impactOccurred()
              }
              LazyVGrid(
                columns: RoundedImage.columnsLargeIcons(width: metrics.size.width),
                pinnedViews: [.sectionHeaders])
              {
                ForEachWithIndex(self.events.recentEvents,id:\.self.nft.id) { index,item in
                  ZStack {
                    
                    RoundedImage(
                      nft:item.nft.nftWithPrice.nft,
                      price:item.nft.nftWithPrice.indicativePrice,
                      collection:item.collection,
                      width: .normal,
                      resolution: .normal,
                      action:item.nft.nftWithPrice.action
                    )
                    .shadow(color:.accentColor,radius:0) //radius:item.isNew ? 10 : 0)
                    .padding()
                    .onTapGesture {
                        //perform some tasks if needed before opening Destination view
                      self.action = item.nft.nftWithPrice.id
                    }
                    
                    NavigationLink(destination: NftDetail(
                      nft:item.nft.nftWithPrice.nft,
                      price:item.nft.nftWithPrice.indicativePrice,
                      collection:item.collection,
                      hideOwnerLink:false,selectedProperties:[]
                    ),tag:item.nft.nftWithPrice.id,selection:$action) {}
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

      }
    }
  }
}
