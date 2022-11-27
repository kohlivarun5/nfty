  //
  //  ENSTextSetCardView.swift
  //  NFTY
  //
  //  Created by Varun Kohli on 11/25/22.
  //

import SwiftUI


import Web3
import PromiseKit

struct ENSTextSetCardView: View {
  
  let item : ENSTextChangedFeed.FeedItem
  
  @State private var isFollowing = false
  
  @State private var friendName : String?
  
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
    
    NavigationLink(destination: PrivateCollectionView(
      account:UserAccount(ethAddress: item.address, nearAccount: nil),
      isOwnerView:false,
      avatar:(item.nft.collection,item.nft.nft),
      ensName:item.ensName,
      page:nil,
      isSheet:false)
    ) {
      
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
          .border(Color.secondary)
          .clipShape(Circle())
          .overlay(Circle().stroke(Color.secondary, lineWidth: 2))
          .shadow(color:.accentColor,radius:0)
        }
        .padding([.leading,.trailing])
        .frame(maxWidth:130)
        
        VStack(alignment:.leading,spacing:5) {
          
          switch(friendName) {
          case .some(let name):
            Text(name)
              .lineLimit(1)
              .colorMultiply(.accentColor)
          case .none:
            HStack {
              AddressLabel(address:item.address.hex(eip55:true),maxLen:15)
                .font(.caption)
              Spacer()
            }
          }
          
          Spacer()
          
          Text(item.value)
            .font(.callout)
            .foregroundColor(.label)
            .multilineTextAlignment(.leading)
          
          BlockTimestampView(
            block:BlocksFetcher.getBlock(blockNumber:BlockNumber.ethereum(item.blockNumber))
          )
          .font(.caption)
          .foregroundColor(Color.tertiaryLabel)
          
          Spacer()
          
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
            .padding([.leading,.trailing])
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
    .background(.ultraThinMaterial)
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
      
      if let name = self.item.ensName { self.friendName = name }
      
    }
  }
}
