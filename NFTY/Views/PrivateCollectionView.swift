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
    case sales
    case owned
    case for_sale
  }
  @State private var tokensPage : TokensPage = .owned
  
  let account : UserAccount
  
  let nft = SampleToken
  let collection = SampleCollection
  
  var body: some View {
    
    
    VStack(spacing:0) {
      
      ProfileViewHeader(account:account,isOwnerView: false,addTopPadding:true)
      
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
        case .sales:
          account.ethAddress.map {
            FriendsFeedView(events:FriendsFeedViewModel(from:$0))
          }
        case .owned:
          WalletTokensView(tokens: getOwnerTokens(account))
        case .for_sale:
          ActivityView(account:account,kind:.sales,emptyMessage:"No Active Sales")
        }
        
      }
      
    }
    .navigationBarTitle("",displayMode:.large)
    .ignoresSafeArea(edges: .top)
  }
}
