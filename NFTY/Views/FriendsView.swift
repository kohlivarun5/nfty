//
//  FriendsView.swift
//  NFTY
//
//  Created by Varun Kohli on 5/16/21.
//

import SwiftUI
import Web3

struct FriendsView: View {
  
  @State private var friends : [String] = []
  
  @State private var isLoading = true
  
  private func updateFriends(_ dict : [String : Bool]) {
    self.isLoading = false
    friends = []
    dict.forEach { (address,isFriend) in
      if (isFriend) {
        (try? EthereumAddress(hex:address, eip55: true)).map { _ in
          friends.append(address)
        }
      }
    }
  }
  
  var body: some View {
    
    VStack {
      switch (isLoading) {
      case true:
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle())
          .scaleEffect(3,anchor: .center)
          .padding()
      case false:
        List(friends, id: \.self) { address in
          NavigationLink(destination: PrivateCollectionView(address: (try! EthereumAddress(hex:address, eip55: true)))) {
            HStack() {
              Text("Address")
                .font(.title3)
              Spacer()
              Text(address.trunc(length:30))
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
          }
        }
      }
    }.onAppear {
      let friendDict = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.friendsDict.rawValue) as? [String : Bool]
      updateFriends(friendDict ?? [:])
    }
  }
}

struct FriendsView_Previews: PreviewProvider {
  static var previews: some View {
    FriendsView()
  }
}
