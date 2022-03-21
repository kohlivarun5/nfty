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
  
  @State private var addresses : [EthereumAddress] = []
  
  @State private var isLoading = true
  
  private func updateFriends(_ dict : [String : String]) {
    self.friends = dict
    self.isLoading = false
    
    print(self.friends)
    
    self.friends.forEach { (key: String, value: String) in
      guard let address = try? EthereumAddress(hex: key, eip55: true) else { return }
      self.addresses.append(address)
    }
    
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
    VStack {
      
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
        }
        
      case .feed:
        FriendsFeedView(addresses:self.addresses,events:FriendsFeedViewModel(addresses: addresses))
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
    .onAppear {
      let friendDict = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.friendsDict.rawValue) as? [String : String]
      updateFriends(friendDict ?? [:])
    }
    
  }
}

struct FriendsView_Previews: PreviewProvider {
  static var previews: some View {
    FriendsView()
  }
}
