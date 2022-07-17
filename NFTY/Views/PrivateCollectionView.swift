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
  let isOwnerView : Bool
  
  let avatar : (Collection,NFT)?
  let ensName : String?
  let isSheet : Bool
  
  private var mintedFeedModel : FriendsFeedViewModel
  private var salesFeedModel : FriendsFeedViewModel
  
  init(account:UserAccount,isOwnerView:Bool) {
    self.account = account
    self.isOwnerView = isOwnerView
    self.avatar = nil
    self.ensName = nil
    self.isSheet = false
    _tokensPage = State(initialValue: .owned)
    self.mintedFeedModel = FriendsFeedViewModel(
      from: [EthereumAddress(hexString:ETH_ADDRESS)!],
      to : [self.account.ethAddress!],
      action:.minted,
      limit:5)
    self.salesFeedModel = FriendsFeedViewModel(from:account.ethAddress!,limit:2)
  }
  
  init(account:UserAccount,isOwnerView:Bool,avatar:(Collection,NFT)?,ensName:String?,page:TokensPage?,isSheet:Bool) {
    self.account = account
    self.isOwnerView = isOwnerView
    self.avatar = avatar
    self.ensName = ensName
    self.isSheet = isSheet
    _tokensPage = State(initialValue: page ?? .owned)
    self.mintedFeedModel = FriendsFeedViewModel(
      from: [EthereumAddress(hexString:ETH_ADDRESS)!],
      to : [self.account.ethAddress!],
      action:.minted,
      limit:5)
    self.salesFeedModel = FriendsFeedViewModel(from:account.ethAddress!,limit:2)
  }
  
  var body: some View {
    
    
    VStack(spacing:0) {
      
      ProfileViewHeader(
        account:account,
        isOwnerView: isOwnerView,
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
          // Text("Sales").tag(TokensPage.for_sale.rawValue)
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
          FriendsFeedView(events:self.mintedFeedModel)
        case .sales:
          FriendsFeedView(events:self.salesFeedModel)
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
