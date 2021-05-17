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
  
  @State private var isFriend : Bool = false
  
  @State private var showDialog = false
  
  let address : EthereumAddress
  
  private func setFriend(_ name:String?) {
    
    switch (NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.friendsDict.rawValue) as? [String : String]) {
    case .none:
      switch name {
      case .some(let name):
        var friends : [String : String] = [:]
        friends[address.hex(eip55: true)] = name
        self.isFriend = true
        NSUbiquitousKeyValueStore.default.set(friends,forKey:CloudDefaultStorageKeys.friendsDict.rawValue)
      case .none:
        self.isFriend = false
      }
    case .some(var friends):
      switch name {
      case .some(let name):
        friends[address.hex(eip55: true)] = name
        self.isFriend = true
      case .none:
        friends.removeValue(forKey: address.hex(eip55: true))
        self.isFriend = false
      }
      NSUbiquitousKeyValueStore.default.set(friends,forKey:CloudDefaultStorageKeys.friendsDict.rawValue)
    }
  }
  
  var body: some View {
    WalletTokensView(tokens: getOwnerTokens(address))
      .onAppear {
        let friends = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.friendsDict.rawValue) as? [String : String]
        self.isFriend = (friends?[address.hex(eip55: true)]) != .none
      }
      .alert(isPresented: $showDialog,
             TextAlert(title: "Enter friend name",message:"") { result in
              if let text = result {
                self.setFriend(text)
              }
             })
      .navigationBarTitle("Private Collection",displayMode: .inline)
      .navigationBarBackButtonHidden(true)
      .navigationBarItems(
        leading: Button(action: {presentationMode.wrappedValue.dismiss()}, label: { BackButton() }),
        trailing: Button(action: {
          if (self.isFriend) {
            self.setFriend(nil)
          } else {
            self.showDialog = true
          }
        }, label: {
          Image(systemName: isFriend ? "person.crop.circle.badge.minus" : "person.crop.circle.badge.plus")
        })
      )
  }
}

struct PrivateCollectionView_Previews: PreviewProvider {
  static var previews: some View {
    PrivateCollectionView(address: EthereumAddress(hexString: "0x0")!)
  }
}
