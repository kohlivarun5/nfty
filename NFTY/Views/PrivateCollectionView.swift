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
  
  let address : EthereumAddress

  private func setFriend(_ isFriend:Bool) {
    
    switch (NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.friendsDict.rawValue) as? [String : Bool]) {
    case .none:
      var friends : [String : Bool] = [:]
      friends[address.hex(eip55: true)] = isFriend
      NSUbiquitousKeyValueStore.default.set(friends,forKey:CloudDefaultStorageKeys.friendsDict.rawValue)
    case .some(var friends):
      friends[address.hex(eip55: true)] = isFriend
      NSUbiquitousKeyValueStore.default.set(friends,forKey:CloudDefaultStorageKeys.friendsDict.rawValue)
    }
  }
  
  var body: some View {
    WalletTokensView(tokens: getOwnerTokens(address))
      .onAppear {
        let friends = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.friendsDict.rawValue) as? [String : Bool]
        self.isFriend = friends?[address.hex(eip55: true)] ?? false
      }
      .navigationBarTitle("Private Collection",displayMode: .inline)
      .navigationBarBackButtonHidden(true)
      .navigationBarItems(
        leading: Button(action: {presentationMode.wrappedValue.dismiss()}, label: { BackButton() }),
        trailing: Button(action: {
            self.isFriend = !self.isFriend
            self.setFriend(self.isFriend)
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
