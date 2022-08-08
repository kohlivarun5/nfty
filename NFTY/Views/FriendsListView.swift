//
//  FriendsListView.swift
//  NFTY
//
//  Created by Varun Kohli on 8/7/22.
//

import SwiftUI
import Web3

struct FriendsListView: View {
  
  let friends : [String : String]
  let addresses : [EthereumAddress]
  
  private func account(_ address:String) -> UserAccount {
    if address.hasSuffix(".near") {
      return UserAccount(ethAddress: nil, nearAccount: address)
    } else {
      return UserAccount(ethAddress: try? EthereumAddress(hex:address, eip55: true), nearAccount: nil)
      
    }
  }
  
  var body: some View {
    List(friends.sorted(by: { $0.value.lowercased() < $1.value.lowercased() }), id: \.key) { address,name in
      NavigationLink(destination: PrivateCollectionView(account:account(address),isOwnerView:false) ){
        HStack() {
          Text(name)
            .font(.title3)
        }
        .padding()
      }
    }
    .navigationBarItems(
      trailing:
        NavigationLink(destination: AddFriendSheet()) {
          Image(systemName:"magnifyingglass.circle.fill")
            .font(.title3)
            .foregroundColor(.accentColor)
            .padding(10)
        }
    )
  }
}
