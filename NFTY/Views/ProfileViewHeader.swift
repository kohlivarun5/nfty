//
//  ProfileViewHeader.swift
//  NFTY
//
//  Created by Varun Kohli on 5/17/22.
//

import SwiftUI
import Web3
import PromiseKit

struct ProfileViewHeader: View {
  
  let account : UserAccount
  let isOwnerView : Bool
  let addTopPadding : Bool
  
  @State var friendName : String?
  @State var avatar : (Collection,NFT)?
  
  @State private var balance : EthereumQuantity? = nil
  
  @State private var isFollowing = false
  
  @State private var showDialog = false
  
  @State private var selectedAvatarToken: NFTTokenEquatable? = nil
  
  @State private var avatarNavLinkActive : Bool = false
  
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
      
      switch (avatar) {
      case .none:
        
        ZStack {
          NftImage(
            nft:SampleToken,
            sample:SAMPLE_PUNKS[0],
            themeColor:SampleCollection.info.themeColor,
            themeLabelColor:SampleCollection.info.themeLabelColor,
            size:.xxsmall,
            resolution:.hd,
            favButton:.none)
          .frame(height:120)
          .colorMultiply(.tertiarySystemBackground)
          .blur(radius: 10)
          .border(Color.secondary)
          .clipShape(Circle())
          .overlay(Circle().stroke(Color.secondary, lineWidth: 2))
          .shadow(color:.accentColor,radius:0)
          
        }
        
      case .some(let info):
        let (collection,nft) = info
        
        NavigationLink(
          destination: NftDetail(
            nft: nft,
            price: TokenPriceType.eager(NFTPriceInfo.init(wei: nil, date: nil, type: TradeEventType.transfer)),
            collection: collection,
            hideOwnerLink: false,
            selectedProperties: [])
        ) {
          NftImage(
            nft:nft,
            sample:collection.info.sample,
            themeColor:collection.info.themeColor,
            themeLabelColor:collection.info.themeLabelColor,
            size:.xxsmall,
            resolution:.hd,
            favButton:.none)
          .frame(height:120)
          .border(Color.secondary)
          .clipShape(Circle())
          .overlay(Circle().stroke(Color.secondary, lineWidth: 2))
          .shadow(color:.accentColor,radius:0)
        }
      }
      
      VStack(alignment:.leading,spacing:5) {
        friendName.map { name in
          HStack {
            Text(name)
              .font(.headline)
            Spacer()
          }
        }
        
        switch(account.nearAccount == friendName) {
        case true:
          EmptyView()
        case false:
          account.nearAccount.map { name in
            HStack {
              Text(name)
                .font(.headline)
                .foregroundColor(.secondary)
              Spacer()
            }
          }
        }
        
        account.ethAddress.map { address in
          HStack {
            AddressLabel(address:address.hex(eip55:true),maxLen:15)
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
        
        switch(isOwnerView,friendName) {
        case (false,.some(let name)):
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
        case (true,.some)/* : // TODO : Support update avatar with wallet connect
                          
                          NavigationLink(
                          destination:WalletTokensSelector(
                          tokens: getOwnerTokens(account),
                          enableNavLinks: false,
                          selectedToken: $selectedAvatarToken)
                          .navigationBarTitle("Choose Avatar NFT",displayMode: .inline)
                          .onChange(of: selectedAvatarToken) { selectedToken in
                          print("Avatar selected \(selectedToken)")
                          
                          // TODO
                          /* self.nftInfo = selectedToken.map { info in
                           (info.token.collection,info.token.nft.nft)
                           } */
                          avatarNavLinkActive = false
                          },
                          isActive: $avatarNavLinkActive
                          ) {
                          HStack {
                          Spacer()
                          Text("Update Avatar")
                          .font(.caption).bold()
                          Spacer()
                          }
                          }
                          .padding([.top,.bottom],5)
                          .padding([.leading,.trailing])
                          .background(.ultraThinMaterial, in: Capsule())
                          .padding(.top,10)
                          .padding(.trailing)
                          .foregroundColor(.accentColor)
                          
                          case */,(true,.none),(false,.none):
          EmptyView()
        }
        
      }
    }
    .padding(.top, addTopPadding ? 50 : 10)
    .padding(.bottom,10)
    .background(.ultraThickMaterial)
    .onAppear {
      
      let friends = NSUbiquitousKeyValueStore.default.object(forKey: CloudDefaultStorageKeys.friendsDict.rawValue) as? [String : String]
      
      switch(key().flatMap { friends?[$0] }) {
      case .some(let name):
        self.friendName = name
        self.isFollowing = true
      case .none:
        self.isFollowing = false
      }
      
      switch(self.friendName,self.avatar) {
      case (.some,.some):
        return
      case (.none,_),(_,.none):
        break
      }
      
      if let address = account.ethAddress {
        
        ENSContract.nameOfOwner(address, eth: web3.eth)
          .done(on:.main) {
            
            if ($0 == .none && self.friendName == .none && self.account.nearAccount != .none) {
              self.friendName = self.account.nearAccount
            }
            
            if let _ = avatar { return }
            
            $0.map {
              self.friendName = $0
              
              // Also do avatar loading
              ENSContract.avatarOfOwner($0, eth: web3.eth)
                .then(on:.main) { avatarOpt -> Promise<ENSTextChangedFeed.NFTItem?> in
                  guard let avatar = avatarOpt else { return Promise.value(nil) }
                  return ENSTextChangedFeed.parseENSAvatar(avatar:avatar)
                }
                .done(on:.main) {
                  $0.map { nftItem in
                    withAnimation {
                      self.avatar = (nftItem.collection,nftItem.nft)
                    }
                  }
                }
                .catch { print($0) }
              
            } }
          .catch { print($0) }
        
        web3.eth.getBalance(address: address, block:.latest)
          .done(on:.main) { balance in
            self.balance = balance
          }.catch { print($0) }
        
      }
      
    }
  }
}
