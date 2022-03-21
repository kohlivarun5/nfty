//
//  FriendsView.swift
//  NFTY
//
//  Created by Varun Kohli on 5/16/21.
//

import SwiftUI
import Web3

struct FriendsView: View {
  
  @State private var friends : [String : String] = [:]
  
  @State private var isLoading = true
  
  private func updateFriends(_ dict : [String : String]) {
    self.friends = dict
    self.isLoading = false
  }
  
  enum Page : Int {
    case feed
    case list
  }
  
  @State private var page : Page = .feed
  
  private func account(_ address:String) -> UserAccount {
    if address.hasSuffix(".near") {
      return UserAccount(ethAddress: nil, nearAccount: address)
    } else {
      return UserAccount(ethAddress: try? EthereumAddress(hex:address, eip55: true), nearAccount: nil)
      
    }
  }
  
  var body: some View {
    
    
    switch(self.page) {
    case .list:
      
      VStack {
        switch (isLoading) {
        case true:
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .scaleEffect(3,anchor: .center)
            .padding()
        case false:
          
          List(friends.sorted(by: { $0.key > $1.key }), id: \.key) { address,name in
            NavigationLink(destination: PrivateCollectionView(account:account(address))){
              HStack() {
                Text(name)
                  .font(.title3)
              }
              .padding()
            }
          }
        }
      }.onAppear {
        let friendDict = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.friendsDict.rawValue) as? [String : String]
        updateFriends(friendDict ?? [:])
      }
      
    case .feed:
      FriendsFeedView()
    }
    
    Picker(selection: Binding<Int>(
      get: { self.page.rawValue },
      set: { tag in
        withAnimation { // needed explicit for transitions
          self.page = Page(rawValue: tag)!
        }
      }),
           label: Text("")) {
      Text("Feed").tag(Page.feed.rawValue)
      Text("Friends").tag(Page.list.rawValue)
    }
           .pickerStyle(SegmentedPickerStyle())
           .colorMultiply(.accentColor)
           .padding([.trailing,.leading])
           .padding(.top,5)
           .padding(.bottom,7)
    
    
    
  }
}

struct FriendsView_Previews: PreviewProvider {
  static var previews: some View {
    FriendsView()
  }
}
