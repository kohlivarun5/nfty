//
//  UserUrlView.swift
//  NFTY
//
//  Created by Varun Kohli on 5/25/21.
//

import SwiftUI
import Web3

struct UserUrlView: View {
  @State private var isFav : Bool = false
  @State private var showDialog = false
  
  @State var account : UserAccount
  @State var friendName : String?
  
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
  
  private func setFriend(_ isFav:Bool) {
    
    guard let key = key() else { return }
    
    self.isFav = isFav
    switch (NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.friendsDict.rawValue) as? [String : String]) {
    case .none:
      switch self.friendName {
      case .some(let name):
        var friends : [String : String] = [:]
        friends[key] = name
        NSUbiquitousKeyValueStore.default.set(friends,forKey:CloudDefaultStorageKeys.friendsDict.rawValue)
      case .none:
        break
      }
    case .some(var friends):
      switch self.friendName {
      case .some(let name):
        friends[key] = name
      case .none:
        friends.removeValue(forKey: key)
      }
      NSUbiquitousKeyValueStore.default.set(friends,forKey:CloudDefaultStorageKeys.friendsDict.rawValue)
    }
  }
  
  var body: some View {
    VStack {
      ZStack {
        HStack {
          Spacer()
          Text(friendName ?? "Private Collection")
            .font(.title2)
          Spacer()
        }
        
        HStack {
          Spacer()
          Button(action: {
            if (self.friendName != nil || self.isFav) {
              self.setFriend(!self.isFav)
            } else {
              self.showDialog = true
            }
          }, label: {
            Image(systemName: isFav ? "person.crop.circle.badge.minus" : "person.crop.circle.badge.plus")
              .renderingMode(.original)
          }).padding(.trailing)
        }
      }.padding(.top)
      
      WalletTokensView(tokens: getOwnerTokens(account))
        .onAppear {
          
          guard let key = key() else { return }
          
          let friends = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.friendsDict.rawValue) as? [String : String]
          if (self.friendName == nil) {
            self.friendName = friends?[key]
          }
          self.isFav = friends?[key] != nil
        }
        .alert(isPresented: $showDialog,
               TextAlert(title: "Enter friend name",message:friendName ?? "") { result in
                if let text = result {
                  self.friendName = text
                  self.setFriend(true)
                }
               })
    }
    
  }
}
