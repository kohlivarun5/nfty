//
//  FollowingFeedView.swift
//  NFTY
//
//  Created by Varun Kohli on 11/29/22.
//

import SwiftUI
import Web3

struct FollowingFeedView: View {
  
  @ObservedObject var userWallet : UserWallet
  
  let friends : [String : String]
  let addresses : [EthereumAddress]
  
  @State var mintedFeed : FriendsFeedViewModel
  @State var salesFeed : FriendsFeedViewModel
  
  init(userWallet: UserWallet, friends: [String : String], addresses: [EthereumAddress]) {
    self.userWallet = userWallet
    self.friends = friends
    self.addresses = addresses
    
    self.mintedFeed = FriendsFeedViewModel(
      from: [EthereumAddress(hexString:ETH_ADDRESS)!],
      to : addresses,
      action:.minted,
      limit:2)
    
    self.salesFeed = FriendsFeedViewModel(from: self.addresses,limit:2)
  }
  
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
          
          FriendsFeedView(events:self.mintedFeed)
          .tag(Page.mints.rawValue)
          .navigationBarTitle("Mints")
          
          FriendsFeedView(events:self.salesFeed)
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
