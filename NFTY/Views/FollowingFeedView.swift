//
//  FollowingFeedView.swift
//  NFTY
//
//  Created by Varun Kohli on 11/29/22.
//

import SwiftUI
import Web3

struct FollowingFeedView: View {
  
  let friends : [String : String]
  let addresses : [EthereumAddress]
  
  enum Page : Int {
    case mints
    case sales
    case following
  }
  
  @State private var page : Page = .mints
  
  var body: some View {
    
    VStack(spacing:0) {
      TabView(selection: Binding<Int>(
        get: { self.page.rawValue },
        set: { tag in
          self.page = Page(rawValue: tag)!
        })) {
          
          FriendsFeedView(events:FriendsFeedViewModel(
            from: [EthereumAddress(hexString:ETH_ADDRESS)!],
            to : addresses,
            action:.minted,
            limit:2))
          .tag(Page.mints.rawValue)
          .navigationBarTitle("Mints")
          
          FriendsFeedView(events:FriendsFeedViewModel(from: self.addresses,limit:2))
            .tag(Page.sales.rawValue)
            .navigationBarTitle("Sales")
          
          FriendsListView(friends:friends,addresses:addresses)
            .tag(Page.following.rawValue)
            .navigationBarTitle("Following")
          
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .navigationBarTitleDisplayMode(.inline)
      
      
      Picker(selection: Binding<Int>(
        get: { self.page.rawValue },
        set: { tag in
          self.page = Page(rawValue: tag)!
        }
      ), label: Text("")) {
        Text("Mints").tag(Page.mints.rawValue)
        Text("Sales").tag(Page.sales.rawValue)
        Text("Following").tag(Page.following.rawValue)
      }
      .pickerStyle(SegmentedPickerStyle())
      .colorMultiply(.accentColor)
      .padding([.trailing,.leading])
      .padding(.bottom,5)
      .padding(.top,10)
      .background(.ultraThinMaterial)
    }
    
  }
}
