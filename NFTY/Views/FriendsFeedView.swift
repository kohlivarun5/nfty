//
//  FriendsFeedView.swift
//  NFTY
//
//  Created by Varun Kohli on 3/20/22.
//

import SwiftUI
import Web3

struct FriendsFeedView: View {
  
  let addresses : [EthereumAddress]
  @StateObject var events : FriendsFeedViewModel
  
  @State private var action: Int? = nil
  @State private var isLoading = true

  var body: some View {
    GeometryReader { metrics in
      ScrollView {
        LazyVGrid(
          columns: Array(
            repeating:GridItem(.flexible(maximum:RoundedImage.NormalSize+80)),
            count: metrics.size.width > RoundedImage.NormalSize * 4 ? 3 : metrics.size.width > RoundedImage.NormalSize * 3 ? 2 : 1),
          pinnedViews: [.sectionHeaders])
        {
          ForEach(events.recentEvents.indices,id:\.self) { index in
            let item = events.recentEvents[index]
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
                self.action = index
              }
              
              NavigationLink(destination: NftDetail(
                nft:nft.nft,
                price:nft.indicativePrice,
                collection:item.collection,
                hideOwnerLink:false,selectedProperties:[]
              ),tag:index,selection:$action) {}
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
    .onAppear {
      if (self.isLoading) {
        self.events.getRecentEvents(currentIndex: 0) {
          DispatchQueue.main.async {
            self.isLoading = false
            //self.refreshButton = .loaded
            // DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 30) { self.triggerRefresh() }
          }
        }
      }
    }
  }
}
