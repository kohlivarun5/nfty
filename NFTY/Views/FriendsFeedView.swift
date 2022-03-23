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
  
  var body: some View {
    
    switch(self.events.isInitialized) {
    case false:
      VStack {
        Spacer()
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle())
          .scaleEffect(2.0, anchor: .center)
          .onAppear {
            self.events.getRecentEvents(currentIndex: 0) {
              DispatchQueue.main.async {
                print("Done isinitialized")
                //self.refreshButton = .loaded
                // DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 30) { self.triggerRefresh() }
              }
            }
          }
        Spacer()
      }
    case true:
      
      switch(self.events.recentEvents.isEmpty) {
      case true:
        VStack {
          Spacer()
          Text("No events")
            .font(.title)
            .foregroundColor(.secondary)
            .onAppear {
              self.events.loadMore {
                DispatchQueue.main.async {
                  print("Done isinitialized")
                  //self.refreshButton = .loaded
                  // DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 30) { self.triggerRefresh() }
                }
              }
            }
          Spacer()
        }
      case false:
        
        GeometryReader { metrics in
          ScrollView {
            LazyVGrid(
              columns: Array(
                repeating:GridItem(.flexible(maximum:RoundedImage.NormalSize+80)),
                count: metrics.size.width > RoundedImage.NormalSize * 4 ? 3 : metrics.size.width > RoundedImage.NormalSize * 3 ? 2 : 1),
              pinnedViews: [.sectionHeaders])
            {
              ForEach(self.events.recentEvents.indices,id:\.self) { index in
                let item = self.events.recentEvents[index]
                let nft = item.nft.nftWithPrice
                
                ZStack {
                  
                  RoundedImage(
                    nft:nft.nft,
                    price:nft.indicativePrice,
                    collection:item.collection,
                    width: .normal,
                    resolution: .normal
                  )
                  .shadow(color:.accentColor,radius:0) //radius:item.isNew ? 10 : 0)
                  .padding()
                  .onTapGesture {
                    //perform some tasks if needed before opening Destination view
                    self.action = nft.id
                  }
                  
                  NavigationLink(destination: NftDetail(
                    nft:nft.nft,
                    price:nft.indicativePrice,
                    collection:item.collection,
                    hideOwnerLink:false,selectedProperties:[]
                  ),tag:nft.id,selection:$action) {}
                    .hidden()
                }.onAppear {
                  DispatchQueue.global(qos:.userInitiated).async {
                    self.events.getRecentEvents(currentIndex:index) {}
                  }
                }
              }
              .textCase(nil)
            }
          }
        }
      }
    }
  }
}
