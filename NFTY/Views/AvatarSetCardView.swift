//
//  AvatarSetCardView.swift
//  NFTY
//
//  Created by Varun Kohli on 7/3/22.
//

import SwiftUI

import Web3
import PromiseKit

struct AvatarSetCardView: View {
  
  let item : ENSTextChangedFeed.FeedItem
  
  @State private var isFollowing = false
  
  @State private var friendName : String?
  @State private var selectedAvatarToken: NFTTokenEquatable? = nil
  
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
    return item.address.hex(eip55: true)
  }
  
  var body: some View {
    
    HStack(spacing:0) {
      
      NavigationLink(
        destination: NftDetail(
          nft: item.nft.nft,
          price: TokenPriceType.eager(NFTPriceInfo.init(wei: nil, date: nil, type: TradeEventType.transfer)),
          collection: item.nft.collection,
          hideOwnerLink: false,
          selectedProperties: [])
      ) {
        NftImage(
          nft:item.nft.nft,
          sample:item.nft.collection.info.sample,
          themeColor:item.nft.collection.info.themeColor,
          themeLabelColor:item.nft.collection.info.themeLabelColor,
          size:.xxsmall,
          resolution:.hd,
          favButton:.none)
        .frame(height:120)
        .border(Color.secondary)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.secondary, lineWidth: 2))
        .shadow(color:.accentColor,radius:0)
      }
      
      NavigationLink(destination: PrivateCollectionView(account:UserAccount(ethAddress: item.address, nearAccount: nil))) {
        VStack(alignment:.leading,spacing:5) {
          
          switch(friendName) {
          case .some(let name):
            Text(name)
              .lineLimit(1)
          case .none:
            HStack {
              AddressLabel(address:item.address.hex(eip55:true),maxLen:15)
              Spacer()
            }
          }
          
          Text(item.nft.nft.name)
            .lineLimit(1)
            .foregroundColor(.secondary)
          Text("#\(String(item.nft.nft.tokenId))")
            .font(.footnote)
            .foregroundColor(.secondary)
          
          switch(friendName) {
          case .some(let name):
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
            .padding(.top,10)
            .padding(.trailing)
            .foregroundColor(isFollowing ? .accentColor : .label)
            .if(!isFollowing){
              $0.colorMultiply(.accentColor)
            }
          case .none:
            EmptyView()
          }
        }
        .padding(.trailing,10)
      }
    }
    .padding([.top,.bottom])
    .background(Color.secondarySystemBackground)
    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius:10, style: .continuous).stroke(Color.secondary, lineWidth: 2))
    .shadow(color:.accentColor,radius:0)
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
      
      let address = item.address
      
      ENSContract.nameOfOwner(address, eth: web3.eth)
        .done(on:.main) {
          print("Got name =\(String(describing: $0)) for address=\(address.hex(eip55: true))")
          $0.map { self.friendName = $0 } }
        .catch { print($0) }
      
    }
  }
}
