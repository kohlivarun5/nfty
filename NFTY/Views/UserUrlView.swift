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
  
  @State var address : EthereumAddress
  @State var friendName : String?
  
  private func setFriend(_ isFav:Bool) {
    self.isFav = isFav
    switch (NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.friendsDict.rawValue) as? [String : String]) {
    case .none:
      switch self.friendName {
      case .some(let name):
        var friends : [String : String] = [:]
        friends[address.hex(eip55: true)] = name
        NSUbiquitousKeyValueStore.default.set(friends,forKey:CloudDefaultStorageKeys.friendsDict.rawValue)
      case .none:
        break
      }
    case .some(var friends):
      switch self.friendName {
      case .some(let name):
        friends[address.hex(eip55: true)] = name
      case .none:
        friends.removeValue(forKey: address.hex(eip55: true))
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
              .accentColor(.secondary)
          }).padding(.trailing)
        }
      }.padding(.top)
      
      WalletTokensView(tokens: getOwnerTokens(address))
        .onAppear {
          let friends = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.friendsDict.rawValue) as? [String : String]
          if (self.friendName == nil) {
            self.friendName = friends?[address.hex(eip55: true)]
          }
          self.isFav = friends?[address.hex(eip55: true)] != nil
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

struct UserUrlView_Previews: PreviewProvider {
  static var previews: some View {
    UserUrlView(address: SAMPLE_WALLET_ADDRESS,friendName:nil)
  }
}
