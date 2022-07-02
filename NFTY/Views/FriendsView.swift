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
    
    DispatchQueue.main.async {
      self.friends = dict
      self.addresses = self.friends.compactMap { (key: String, value: String) in
        try? EthereumAddress(hex: key, eip55: true)
      }
      self.feedModel = FriendsFeedViewModel(from: self.addresses,limit:2)
      self.mintedModel = FriendsFeedViewModel(
        from: [EthereumAddress(hexString: "0x0000000000000000000000000000000000000000")!],
        to : self.addresses,
        action:.minted,
        limit:2)
      self.isLoading = false
    }
  }
  
  enum Page : Int {
    case feed
    case minted
    case list
  }
  
  @State private var page : Page = .feed
  
  @State private var feedModel : FriendsFeedViewModel
  @State private var mintedModel : FriendsFeedViewModel
  
  init() {
    self.feedModel = FriendsFeedViewModel(from: [],limit:2)
    self.mintedModel = FriendsFeedViewModel(
      from: [EthereumAddress(hexString: "0x0000000000000000000000000000000000000000")!],
      to : [],
      action:.minted,
      limit:2)
  }
  
  private func title(_ page:Page) -> String {
    switch(page) {
    case .feed:
      return "Sales"
    case .list:
      return "Friends"
    case .minted:
      return "Mints"
    }
  }
  
  private func account(_ address:String) -> UserAccount {
    if address.hasSuffix(".near") {
      return UserAccount(ethAddress: nil, nearAccount: address)
    } else {
      return UserAccount(ethAddress: try? EthereumAddress(hex:address, eip55: true), nearAccount: nil)
      
    }
  }
  
  var body: some View {
    
    switch(self.isLoading) {
    case true:
      ProgressView()
        .progressViewStyle(CircularProgressViewStyle())
        .scaleEffect(3,anchor: .center)
        .padding()
        .onAppear {
          let friendDict = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.friendsDict.rawValue) as? [String : String]
          updateFriends(friendDict ?? [:])
        }
    case false:
      
      VStack(spacing:0) {
        switch(self.page,self.addresses.isEmpty) {
        case (.list,_),(_,true):
          List(friends.sorted(by: { $0.value.lowercased() < $1.value.lowercased() }), id: \.key) { address,name in
            NavigationLink(destination: PrivateCollectionView(account:account(address)) ){
              HStack() {
                Text(name)
                  .font(.title3)
              }
              .padding()
            }
          }
          .navigationBarItems(
            trailing:
              NavigationLink(destination: AddFriendSheet()) {
                Image(systemName:"magnifyingglass.circle.fill")
                  .font(.title3)
                  .foregroundColor(.accentColor)
                  .padding(10)
              }
          )
        case (.feed,false):
          FriendsFeedView(events:self.feedModel)
        case (.minted,false):
          FriendsFeedView(events:self.mintedModel)
        }
        
        if (!self.addresses.isEmpty) {
          Picker(selection: Binding<Int>(
            get: { self.page.rawValue },
            set: { tag in
              withAnimation { // needed explicit for transitions
                self.page = Page(rawValue: tag)!
              }
            }),
                 label: Text("")) {
            Text("Mints").tag(Page.minted.rawValue)
            Text("Sales").tag(Page.feed.rawValue)
            Text("Following").tag(Page.list.rawValue)
          }
                 .pickerStyle(SegmentedPickerStyle())
                 .colorMultiply(.accentColor)
                 .padding([.trailing,.leading])
                 .padding(.top,5)
                 .padding(.bottom,7)
        }
        
      }
      .navigationBarTitle(title(self.page),displayMode: .inline)
      
    }
  }
}

struct FriendsView_Previews: PreviewProvider {
  static var previews: some View {
    FriendsView()
  }
}
