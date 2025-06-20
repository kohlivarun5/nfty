//
//  TokenTradeActions.swift
//  NFTY
//
//  Created by Varun Kohli on 7/25/21.
//

import SwiftUI
import Web3
import PromiseKit

struct TokenTradeActions: View {
  
  let nft:NFT
  let price:TokenPriceType
  
  let collection : Collection
  
  let size : NftImage.Size
  
  @ObservedObject var userWallet: UserWallet
  
  @StateObject var userSettings = UserSettings()
  
  @State private var tradeActions : TradeActionInfo? = nil
  
  @State var currentBidPrice : PriceUnit?
  @State var currentAskPrice : PriceUnit?
  
  enum ActionsState {
    case buyActions
    case sellActions
  }
  @State private var actionsState : ActionsState? = nil
  
  
  init(
    nft:NFT,
    price:TokenPriceType,
    collection:Collection,
    size : NftImage.Size,
    userWallet: UserWallet) {
      
      self.nft = nft
      self.price = price
      self.collection = collection
      self.size = size
      self.userWallet = userWallet
    }
  
  var body: some View {
    
    VStack {
      
      switch (tradeActions,currentBidPrice,currentAskPrice) {
      case (.none,_,_),(_,.none,.none):
        EmptyView()
        
      case (.some,.some(let bidPrice),.none):
        HStack {
          Spacer()
          Text("Current Bid")
            .foregroundColor(.secondary)
            .italic()
          Spacer()
          UsdEthHText(price: bidPrice,fontWeight:.semibold)
          Spacer()
        }
        .font(.title3)
        .padding(.top,10)
        .padding(.bottom,actionsState == nil ? 10 : 2)
        
      case (.some,.none,.some(let askPrice)):
        HStack {
          Spacer()
          Text("Asking For")
            .foregroundColor(.secondary)
            .italic()
          Spacer()
          UsdEthHText(price: askPrice,fontWeight:.semibold)
          Spacer()
        }
        .font(.title3)
        .padding(.top,10)
        .padding(.bottom,actionsState == nil ? 10 : 2)
        
      case (.some,.some(let bidPrice),.some(let askPrice)):
        HStack(alignment:.center) {
          
          HStack {
            Spacer()
            VStack(alignment: .center) {
              Text("Bid")
                .italic()
                .foregroundColor(.secondary)
                .padding(.bottom,1)
              UsdEthHText(price: bidPrice,fontWeight:.semibold)
            }
            Spacer()
          }
          Divider().frame(height:25)
          HStack {
            Spacer()
            VStack(alignment: .center) {
              Text("Ask")
                .italic()
                .foregroundColor(.secondary)
                .padding(.bottom,1)
              UsdEthHText(price: askPrice,fontWeight:.semibold)
            }
            Spacer()
          }
        }
        .padding(.top,10)
        .padding(.bottom,actionsState == nil ? 10 : 2)
      }
      
      HStack {
        
        switch(actionsState,tradeActions) {
        case (.none,_),(_,.none):
          EmptyView()
          
        case (.some(let actions),.some(let tradeActions)):
          HStack {
            switch(actions,tradeActions.tradeActions.actions) {
            case (.buyActions,.some(let txActions)):
              WithWalletProviderView(
                userWallet:userWallet,
                instruction:"Sign-In to activate trading",
                label: {
                  HStack {
                    Spacer()
                    Text("Buy")
                      .foregroundColor(.black)
                      .font(.title3)
                      .bold()
                    Spacer()
                  }
                  .padding(10)
                  .background(
                    RoundedCorners(
                      color: .accentColor,
                      tl: 20, tr: 20, bl: 20, br: 20))
                  .padding([.leading,.trailing],50)
                },content: { walletProvider in
                  TokenBuyView(
                    nft: nft,
                    price:price,
                    sample: collection.info.sample,
                    themeColor:collection.info.themeColor,
                    themeLabelColor:collection.info.themeLabelColor,
                    size: .xsmall,
                    rarityRank:collection.info.rarityRanking,
                    tradeActions: tradeActions,
                    actions:txActions,
                    walletProvider:walletProvider
                  )
                })
            case (.buyActions,.none):
               DappLink.DappLinkView(destination: DappLink.openSeaPath(nft: nft), label: {
                HStack {
                  Spacer()
                  Text("Buy")
                    .foregroundColor(.black)
                    .font(.title3)
                    .bold()
                  Spacer()
                }
              })
              .padding(10)
              .background(
                RoundedCorners(
                  color: .accentColor,
                  tl: 20, tr: 20, bl: 20, br: 20))
              .padding([.leading,.trailing],50)
            case (.sellActions,.some),(.sellActions,.none):
              DappLink.DappLinkView(destination: DappLink.openSeaPath(nft: nft), label: {
                HStack {
                  Spacer()
                  Text("Sell")
                    .foregroundColor(.black)
                    .font(.title3)
                    .bold()
                  Spacer()
                }
              })
              .padding(10)
              .background(
                RoundedCorners(
                  color: .accentColor,
                  tl: 20, tr: 20, bl: 20, br: 20))
              .padding([.leading,.trailing],50)
            }
          }
          .padding(.bottom,10)
          .padding(.top,currentBidPrice == nil && currentAskPrice == nil ? 10 : 0)
        }
      }
      
    }
    .onAppear {
      let contract = collection.contract
      contract.tradeActions.map { tradeActions in
        self.tradeActions = TradeActionInfo(
          tradeActions: tradeActions,
          bidAsk: tradeActions.getBidAsk(nft.tokenId,nil))
        
        self.tradeActions?.bidAsk
          .done {
            self.currentBidPrice = $0.bid.map { $0.price }
            self.currentAskPrice = $0.ask.map { $0.price }
          }
          .catch { print($0) }
      }
      
      contract.ownerOf(nft.tokenId)
        .done { account in
          self.actionsState = self.tradeActions.flatMap { _ in
            let walletAccount = userWallet.userAccount()
            return (walletAccount?.ethAddress == account?.ethAddress
                    || (walletAccount?.nearAccount != nil && account?.nearAccount != nil && walletAccount?.nearAccount == account?.nearAccount))
            ? .sellActions : .buyActions
          }
        }
        .catch { print($0) }
      
    }
  }
}

struct TokenTradeActions_Previews: PreviewProvider {
  static var previews: some View {
    TokenTradeActions(
      nft: SampleToken,
      price:.eager(NFTPriceInfo(wei:0,blockNumber: nil,type:.ask)),
      collection:SampleCollection,
      size:.normal,
      userWallet: UserWallet())
    .background(
      RoundedCorners(
        color: .secondarySystemBackground,
        tl: 20, tr: 20, bl: 0, br: 0))
    
  }
}
