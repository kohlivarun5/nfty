//
//  UserUrlView.swift
//  NFTY
//
//  Created by Varun Kohli on 5/25/21.
//

import SwiftUI
import Web3

struct UserUrlView: View {
  @State private var friendName : String? = nil
  @State private var showDialog = false
  
  let address : EthereumAddress
  
  private func setFriend(_ name:String?) {
    self.friendName = name
    switch (NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.friendsDict.rawValue) as? [String : String]) {
    case .none:
      switch name {
      case .some(let name):
        var friends : [String : String] = [:]
        friends[address.hex(eip55: true)] = name
        NSUbiquitousKeyValueStore.default.set(friends,forKey:CloudDefaultStorageKeys.friendsDict.rawValue)
      case .none:
        break
      }
    case .some(var friends):
      switch name {
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
        /* HStack {
          Spacer()
          Button(action: {
            switch (self.friendName) {
            case .none:
              self.showDialog = true
            case .some:
              self.setFriend(nil)
            }
          }, label: {
            Image(systemName: friendName == .none ? "person.crop.circle.badge.plus" : "person.crop.circle.badge.minus")
          })
        }.padding(.trailing) */
      }.padding(.top)
      
      WalletTokensView(tokens: getOwnerTokens(address))
        .onAppear {
          let friends = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.friendsDict.rawValue) as? [String : String]
          self.friendName = friends?[address.hex(eip55: true)]
        }
    }
  }
}

struct UserUrlView_Previews: PreviewProvider {
  static var previews: some View {
    UserUrlView(address: SAMPLE_WALLET_ADDRESS)
  }
}
