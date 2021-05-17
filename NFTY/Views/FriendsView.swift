//
//  FriendsView.swift
//  NFTY
//
//  Created by Varun Kohli on 5/16/21.
//

import SwiftUI
import Web3

struct FriendsView: View {
  
  @State private var friends : [String : String] = [:]
  
  @State private var isLoading = true
  
  private func updateFriends(_ dict : [String : String]) {
    self.friends = dict
    self.isLoading = false
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
        
        List(friends.sorted(by: { $0.key > $1.key }), id: \.key) { address,name in
          NavigationLink(destination: PrivateCollectionView(address: (try! EthereumAddress(hex:address, eip55: true)))) {
            HStack() {
              Text(name)
                .font(.title3)
              Spacer()
              AddressLabel(address:address,maxLen:20)
            }
            .padding()
          }
        }
      }
    }.onAppear {
      let friendDict = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.friendsDict.rawValue) as? [String : String]
      updateFriends(friendDict ?? [:])
    }
  }
}

struct FriendsView_Previews: PreviewProvider {
  static var previews: some View {
    FriendsView()
  }
}
