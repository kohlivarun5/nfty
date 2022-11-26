//
//  ENSTextChangedFeedView.swift
//  NFTY
//
//  Created by Varun Kohli on 11/25/22.
//

import SwiftUI
import Web3

struct ENSTextChangedFeedView: View {
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
      self.refreshButton = .loaded
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
      
      VStack {
        
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
                spacing:20,
                pinnedViews: [.sectionHeaders])
              {
                ForEachWithIndex(self.events.recentEvents,id:\.self.nft.nft.id) { index,item in
                  ENSTextSetCardView(item: item)
                    .padding(5)
                    .onAppear {
                      DispatchQueue.global(qos:.userInitiated).async {
                        self.events.getRecentEvents(currentIndex:index) {}
                      }
                    }
                }
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
}
