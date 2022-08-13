//
//  PrivateCollectionVIew.swift
//  NFTY
//
//  Created by Varun Kohli on 5/16/21.
//

import SwiftUI
import Web3

struct PrivateCollectionView: View {
  
  enum TokensPage : Int {
    case owned
    case sales
    case minted
    case saved
    case following
  }
  @State private var tokensPage : TokensPage
  
  let account : UserAccount
  let isOwnerView : Bool
  let avatar : (Collection,NFT)?
  let ensName : String?
  let isSheet : Bool
  
  let friends : [String : String]
  let addresses : [EthereumAddress]

  init(account:UserAccount,isOwnerView:Bool) {
    self.account = account
    self.isOwnerView = isOwnerView
    self.avatar = nil
    self.ensName = nil
    self.isSheet = false
    _tokensPage = State(initialValue: .owned)
    
    if (isOwnerView) {
      self.friends = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.friendsDict.rawValue) as? [String : String] ?? [:]
      self.addresses = self.friends.compactMap { (key: String, value: String) in
        try? EthereumAddress(hex: key, eip55: true)
      }
    } else {
      self.friends = [:]
      self.addresses = []
    }
  }
  
  init(account:UserAccount,isOwnerView:Bool,avatar:(Collection,NFT)?,ensName:String?,page:TokensPage?,isSheet:Bool) {
    self.account = account
    self.isOwnerView = isOwnerView
    self.avatar = avatar
    self.ensName = ensName
    self.isSheet = isSheet
    _tokensPage = State(initialValue: page ?? .owned)
    
    if (isOwnerView) {
      self.friends = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.friendsDict.rawValue) as? [String : String] ?? [:]
      self.addresses = self.friends.compactMap { (key: String, value: String) in
        try? EthereumAddress(hex: key, eip55: true)
      }
    } else {
      self.friends = [:]
      self.addresses = []
    }
  }
  
  var body: some View {
    
    
    VStack(spacing:0) {
      
      ProfileViewHeader(
        account:account,
        isOwnerView: isOwnerView,
        addTopPadding:!isSheet,
        friendName: self.ensName,
        avatar:self.avatar)
           
      VStack(spacing:0) {
        
        Picker(
          selection: Binding<Int>(
            get: { self.tokensPage.rawValue },
            set: { tag in
              withAnimation { // needed explicit for transitions
                self.tokensPage = TokensPage(rawValue: tag)!
              }
            }),
          label: Text("")) {
            Text("Owned").tag(TokensPage.owned.rawValue)
            if (self.account.ethAddress != nil) { Text("Activity").tag(TokensPage.sales.rawValue) }
            if (self.account.ethAddress != nil) { Text("Minted").tag(TokensPage.minted.rawValue) }
            if (self.isOwnerView) {
              Text("Saved").tag(TokensPage.saved.rawValue)
              Text("Following").tag(TokensPage.following.rawValue)
            }
            
          }
          .pickerStyle(SegmentedPickerStyle())
          .colorMultiply(.accentColor)
          .padding([.trailing,.leading])
          .padding(.top,5)
          .padding(.bottom,7)
        
        switch(self.tokensPage) {
        case .owned:
          WalletTokensView(tokens: getOwnerTokens(account),redactPrice:false)
        case .sales:
          account.ethAddress.map {
            FriendsFeedView(events:FriendsFeedViewModel(from:$0,limit:2))
          }
        case .minted:
          account.ethAddress.map {
            FriendsFeedView(
              events:FriendsFeedViewModel(
                  from: [EthereumAddress(hexString:ETH_ADDRESS)!],
                  to : [$0],
                  action:.minted,
                  limit:5)
              )
          }
        case .saved:
          FavoritesView()
        case .following:
          FriendsListView(friends:friends,addresses:addresses)
        }
      }
    }
    .navigationBarTitle("",displayMode:.large)
    .ignoresSafeArea(edges: .top)
  }
}
