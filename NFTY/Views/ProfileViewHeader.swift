//
//  ProfileViewHeader.swift
//  NFTY
//
//  Created by Varun Kohli on 5/17/22.
//

import SwiftUI
import Web3

struct ProfileViewHeader: View {
  
  let account : UserAccount
  
  @State private var balance : EthereumQuantity? = nil
  
  @State private var isFollowing = false
  
  @State private var friendName : String?
  @State private var showDialog = false
  
  private func setFriend(_ name:String) {
    
    guard let key = key() else { return }
    
    self.isFollowing = !self.isFollowing
    switch (NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.friendsDict.rawValue) as? [String : String]) {
    case .none:
      switch self.isFollowing {
      case true:
        var friends : [String : String] = [:]
        friends[key] = name
        NSUbiquitousKeyValueStore.default.set(friends,forKey:CloudDefaultStorageKeys.friendsDict.rawValue)
      case false:
        break
      }
    case .some(var friends):
      switch self.isFollowing {
      case true:
        friends[key] = name
      case false:
        friends.removeValue(forKey: key)
      }
      NSUbiquitousKeyValueStore.default.set(friends,forKey:CloudDefaultStorageKeys.friendsDict.rawValue)
    }
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
  
  var body: some View {
    
    HStack(spacing:0) {
      
      NftImage(
        nft:SampleToken,
        sample:SAMPLE_PUNKS[0],
        themeColor:SampleCollection.info.themeColor,
        themeLabelColor:SampleCollection.info.themeLabelColor,
        size:.xxsmall,
        resolution:.hd,
        favButton:.none)
      .frame(height:120)
      .border(Color.secondary)
      .clipShape(Circle())
      .overlay(Circle().stroke(Color.secondary, lineWidth: 2))
      .shadow(color:.accentColor,radius:0)
      
      VStack(alignment:.leading,spacing:5) {
        friendName.map { name in
          HStack {
            Text(name)
              .font(.headline)
            Spacer()
          }
        }
        
        balance.map { wei in
          HStack {
            UsdEthVText(price:.wei(wei.quantity),fontWeight: .semibold,alignment:.leading)
              .foregroundColor(.secondary)
            Spacer()
          }
        }
        
        friendName.map { name in
          Button(action: {
            setFriend(name)
          }) {
            HStack {
              Spacer()
              Text(isFollowing ? "Unfollow" : "Follow")
                .font(.caption).bold()
              Spacer()
            }
          }
          .padding([.top,.bottom],5)
          .padding([.leading,.trailing])
          .background(.ultraThinMaterial, in: Capsule())
          .padding(.top)
          .padding(.trailing)
          .foregroundColor(isFollowing ? .accentColor : .label)
          .if(!isFollowing){
            $0.colorMultiply(.accentColor)
          }
        }
        
      }
    }
    /* .alert(isPresented: $showDialog,
     TextAlert(title: "Enter friend name",message:"",text:self.friendName ?? "") { result in
     if let text = result {
     self.setFriend(text)
     }
     }) */
    .onAppear {
      
      let friends = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.friendsDict.rawValue) as? [String : String]
      
      switch(key().flatMap { friends?[$0] }) {
      case .some(let name):
        self.friendName = name
        self.isFollowing = true
      case .none:
        self.isFollowing = false
        self.friendName = .none
      }
      
      if let address = account.ethAddress {
        
        ENSContract.nameOfOwner(address, eth: web3.eth)
          .done(on:.main) { $0.map { self.friendName = $0 } }
          .catch { print($0) }
        
        web3.eth.getBalance(address: address, block:.latest)
          .done(on:.main) { balance in
            self.balance = balance
          }.catch { print($0) }
        
      }
      
    }
  }
}
