//
//  PrivateCollectionVIew.swift
//  NFTY
//
//  Created by Varun Kohli on 5/16/21.
//

import SwiftUI
import Web3

struct PrivateCollectionView: View {
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  
  @State private var friendName : String? = nil
  @State private var fallbackName : String? = nil
  
  @State private var showDialog = false
  
  let account : UserAccount
  
  enum TokensPage : Int {
    case bought
    case sales
    case owned
    case for_sale
  }
  
  @State private var tokensPage : TokensPage
  
  init(account:UserAccount) {
    self.account = account
    _tokensPage = State(initialValue: self.account.ethAddress == nil ? .owned : .sales)
  }
  
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
  
  var body: some View {
    
    VStack(spacing:10) {
      
      ProfileViewHeader(name:friendName,account:account)
        .padding(.top,-40)
        .padding([.leading,.trailing],60)
        .navigationBarTitle("",displayMode:.inline)
      
      Picker(selection: Binding<Int>(
        get: { self.tokensPage.rawValue },
        set: { tag in
          withAnimation { // needed explicit for transitions
            self.tokensPage = TokensPage(rawValue: tag)!
          }
        }),
             label: Text("")) {
        if (self.account.ethAddress != nil) { Text("Sales").tag(TokensPage.sales.rawValue) }
        // if (self.account.ethAddress != nil) { Text("Bought").tag(TokensPage.bought.rawValue) }
        Text("Owned").tag(TokensPage.owned.rawValue)
        Text("For Sale").tag(TokensPage.for_sale.rawValue)
      }
             .pickerStyle(SegmentedPickerStyle())
             .colorMultiply(.accentColor)
             .padding([.trailing,.leading])
      
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
    .alert(isPresented: $showDialog,
           TextAlert(title: "Enter friend name",message:"",text:self.fallbackName ?? "") { result in
      if let text = result {
        self.setFriend(text)
      }
    })
    //.navigationBarTitle(friendName ?? "Private Collection",displayMode: .inline)
    .navigationBarBackButtonHidden(true)
    .navigationBarItems(
      leading: Button(action: {presentationMode.wrappedValue.dismiss()}, label: { BackButton() }),
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
    .ignoresSafeArea(edges:.top)
  }
}
