//
//  PrivateCollectionVIew.swift
//  NFTY
//
//  Created by Varun Kohli on 5/16/21.
//

import SwiftUI
import Web3

struct PrivateCollectionView: View {
  
  enum TokensPage : Int {
    case bought
    case minted
    case sales
    case owned
    case for_sale
  }
  @State private var tokensPage : TokensPage
  
  let account : UserAccount
  
  let avatar : (Collection,NFT)?
  let ensName : String?
  let isSheet : Bool
  
  init(account:UserAccount) {
    self.account = account
    self.avatar = nil
    self.ensName = nil
    self.isSheet = false
    _tokensPage = State(initialValue: .owned)
  }
  
  init(account:UserAccount,avatar:(Collection,NFT)?,ensName:String?,page:TokensPage?,isSheet:Bool) {
    self.account = account
    self.avatar = avatar
    self.ensName = ensName
    self.isSheet = isSheet
    _tokensPage = State(initialValue: page ?? .owned)
  }
  
  var body: some View {
    
    
    VStack(spacing:0) {
      
      ProfileViewHeader(
        account:account,
        isOwnerView: false,
        addTopPadding:!isSheet,
        friendName: self.ensName,
        avatar:self.avatar)
      
      VStack(spacing:0) {
        
        Picker(selection: Binding<Int>(
          get: { self.tokensPage.rawValue },
          set: { tag in
            withAnimation { // needed explicit for transitions
              self.tokensPage = TokensPage(rawValue: tag)!
            }
          }),
               label: Text("")) {
          Text("Owned").tag(TokensPage.owned.rawValue)
          if (self.account.ethAddress != nil) { Text("Activity").tag(TokensPage.sales.rawValue) }
          if (self.account.ethAddress != nil) { Text("Minted").tag(TokensPage.minted.rawValue) }
          // if (self.account.ethAddress != nil) { Text("Bought").tag(TokensPage.bought.rawValue) }
          Text("Sales").tag(TokensPage.sales.rawValue)
        }
               .pickerStyle(SegmentedPickerStyle())
               .colorMultiply(.accentColor)
               .padding([.trailing,.leading])
               .padding(.top,5)
               .padding(.bottom,7)
        
        switch(self.tokensPage) {
        case .bought:
          account.ethAddress.map {
            FriendsFeedView(events:FriendsFeedViewModel(to:$0))
          }
        case .minted:
          account.ethAddress.map {
            FriendsFeedView(
              events:FriendsFeedViewModel(
                  from: [EthereumAddress(hexString:ETH_ADDRESS)!],
                  to : [$0],
                  action:.minted,
                  limit:5)
              )
          }
        case .sales:
          account.ethAddress.map {
            FriendsFeedView(events:FriendsFeedViewModel(from:$0,limit:2))
          }
        case .owned:
          WalletTokensView(tokens: getOwnerTokens(account),redactPrice:false)
        case .for_sale:
          ActivityView(account:account,kind:.sales,emptyMessage:"No Active Sales")
        }
        
      }
      
    }
    .navigationBarTitle("",displayMode:.large)
    .ignoresSafeArea(edges: .top)
  }
}
