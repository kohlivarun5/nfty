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
    case activity
    case owned
    case sales
  }
  
  @State private var tokensPage : TokensPage
  
  init(account:UserAccount) {
    self.account = account
    _tokensPage = State(initialValue: self.account.ethAddress == nil ? .owned : .activity)
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
    
    VStack(spacing:0) {
      
      switch(self.tokensPage) {
      case .activity:
        account.ethAddress.map {
          FriendsFeedView(events:FriendsFeedViewModel(owner:$0))
        }
      case .owned:
        WalletTokensView(tokens: getOwnerTokens(account))
      case .sales:
        ActivityView(account:account,kind:.sales,emptyMessage:"No Active Sales")
      }
      
      Picker(selection: Binding<Int>(
        get: { self.tokensPage.rawValue },
        set: { tag in
          withAnimation { // needed explicit for transitions
            self.tokensPage = TokensPage(rawValue: tag)!
          }
        }),
             label: Text("")) {
        if (self.account.ethAddress != nil) {
          Text("Activity").tag(TokensPage.activity.rawValue)
        }
        Text("Owned").tag(TokensPage.owned.rawValue)
        Text("Sales").tag(TokensPage.sales.rawValue)
      }
             .pickerStyle(SegmentedPickerStyle())
             .colorMultiply(.accentColor)
             .padding([.trailing,.leading])
             .padding(.top,5)
             .padding(.bottom,7)
      
    }
    .onAppear {
      guard let key = key() else { return }
      let friends = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.friendsDict.rawValue) as? [String : String]
      self.friendName = friends?[key]
      self.fallbackName = friendName ?? account.nearAccount
    }
    .alert(isPresented: $showDialog,
           TextAlert(title: "Enter friend name",message:"",text:self.fallbackName ?? "") { result in
      if let text = result {
        self.setFriend(text)
      }
    })
    .navigationBarTitle(friendName ?? "Private Collection",displayMode: .inline)
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
  }
}
