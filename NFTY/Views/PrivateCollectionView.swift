//
//  PrivateCollectionVIew.swift
//  NFTY
//
//  Created by Varun Kohli on 5/16/21.
//

import SwiftUI
import Web3

struct PrivateCollectionView: View {
  
  @State private var friendName : String? = nil
  @State private var fallbackName : String? = nil
  
  @State private var showDialog = false
  
  enum TokensPage : Int {
    case bought
    case sales
    case owned
    case for_sale
  }
  @State private var tokensPage : TokensPage = .owned
  
  let account : UserAccount
  
  private func key() -> String? {
    switch(account.ethAddress,account.nearAccount) {
    case (.some(let address),_):
      return address.hex(eip55: true)
    case (_,.some(let account)):
      return account
    case (.none,.none):
      return nil
    }
  }
  
  private func setFriend(_ name:String?) {
    
    guard let key = key() else { return }
    
    self.friendName = name
    switch (NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.friendsDict.rawValue) as? [String : String]) {
    case .none:
      switch name {
      case .some(let name):
        var friends : [String : String] = [:]
        friends[key] = name
        NSUbiquitousKeyValueStore.default.set(friends,forKey:CloudDefaultStorageKeys.friendsDict.rawValue)
      case .none:
        break
      }
    case .some(var friends):
      switch name {
      case .some(let name):
        friends[key] = name
      case .none:
        friends.removeValue(forKey: key)
      }
      NSUbiquitousKeyValueStore.default.set(friends,forKey:CloudDefaultStorageKeys.friendsDict.rawValue)
    }
  }
  
  let nft = SampleToken
  let collection = SampleCollection
  
  var body: some View {
    
    
    VStack(spacing:0) {
      
      ProfileViewHeader(name:friendName,account:account)
        .padding(.top,50)
        .padding(.bottom,10)
        .background(Color.secondarySystemBackground)
        .onAppear {
          guard let key = key() else { return }
          let friends = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.friendsDict.rawValue) as? [String : String]
          self.friendName = friends?[key]
          self.fallbackName = friendName ?? account.nearAccount
          
          guard let address = self.account.ethAddress else { return }
          ENSContract.nameOfOwner(address, eth: web3.eth)
            .done(on:.main) { $0.map { self.friendName = $0 } }
            .catch { print($0) }
        }
      
      VStack(spacing:0) {
        
        Picker(selection: Binding<Int>(
          get: { self.tokensPage.rawValue },
          set: { tag in
            withAnimation { // needed explicit for transitions
              self.tokensPage = TokensPage(rawValue: tag)!
            }
          }),
               label: Text("")) {
          Text("Owned").tag(TokensPage.owned.rawValue)
          if (self.account.ethAddress != nil) { Text("Activity").tag(TokensPage.sales.rawValue) }
          // if (self.account.ethAddress != nil) { Text("Bought").tag(TokensPage.bought.rawValue) }
          Text("Sales").tag(TokensPage.sales.rawValue)
        }
               .pickerStyle(SegmentedPickerStyle())
               .colorMultiply(.accentColor)
               .padding([.trailing,.leading])
               .padding(.top,5)
               .padding(.bottom,7)
        
        switch(self.tokensPage) {
        case .bought:
          account.ethAddress.map {
            FriendsFeedView(events:FriendsFeedViewModel(to:$0))
          }
        case .sales:
          account.ethAddress.map {
            FriendsFeedView(events:FriendsFeedViewModel(from:$0))
          }
        case .owned:
          WalletTokensView(tokens: getOwnerTokens(account))
        case .for_sale:
          ActivityView(account:account,kind:.sales,emptyMessage:"No Active Sales")
        }
        
      }
      
    }
    .navigationBarTitle("",displayMode:.large)
    .ignoresSafeArea(edges: .top)
    .navigationBarItems(
      trailing: Button(action: {
        switch (self.friendName) {
        case .none:
          self.showDialog = true
        case .some:
          self.setFriend(nil)
        }
      }, label: {
        Image(systemName: friendName == .none ? "person.crop.circle.badge.plus" : "person.crop.circle.badge.minus")
          .renderingMode(.original)
      })
    )
  }
}
