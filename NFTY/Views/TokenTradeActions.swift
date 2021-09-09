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
  let sample:String
  let themeColor : Color
  let themeLabelColor : Color
  let size : NftImage.Size
  let rarityRank : RarityRanking?
  @ObservedObject var userWallet: UserWallet
  
  @StateObject var userSettings = UserSettings()
  
  @State private var walletAddress : EthereumAddress? = nil
  
  @State private var tradeActions : TradeActionInfo? = nil
  
  @State var currentBidPriceInWei : BigUInt?
  @State var currentAskPriceInWei : BigUInt?
  
  enum ActionsState {
    case buyActions
    case sellActions
  }
  @State private var actionsState : ActionsState? = nil

  
  init(
    nft:NFT,
    price:TokenPriceType,
    sample:String,
    themeColor : Color,
    themeLabelColor : Color,
    size : NftImage.Size,
    rarityRank : RarityRanking?,
    userWallet: UserWallet) {
    
    self.nft = nft
    self.price = price
    self.sample = sample
    self.themeColor = themeColor
    self.themeLabelColor = themeLabelColor
    self.size = size
    self.rarityRank = rarityRank
    self.userWallet = userWallet
  }
  
  var body: some View {
    
    VStack {
      
      switch (tradeActions,currentBidPriceInWei,currentAskPriceInWei) {
      case (.none,_,_),(_,.none,.none):
        EmptyView()
        
      case (.some,.some(let bidPrice),.none):
        HStack {
          Spacer()
          Text("Current Bid")
            .foregroundColor(.secondary)
            .italic()
          Spacer()
          UsdText(wei: bidPrice,fontWeight:.semibold)
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
          UsdText(wei: askPrice,fontWeight:.semibold)
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
              UsdText(wei: bidPrice,fontWeight:.semibold)
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
              UsdText(wei: askPrice,fontWeight:.semibold)
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
            /*case (.buyActions,.some(let txActions)):
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
                    sample: sample,
                    themeColor:themeColor,
                    themeLabelColor:themeLabelColor,
                    size: .xsmall,
                    rarityRank:rarityRank,
                    tradeActions: tradeActions,
                    actions:txActions,
                    walletProvider:walletProvider
                  )
                })
 */
            case (.buyActions,.none),(.buyActions,.some):
              Link(destination:DappLink.openSeaUrl(nft:nft,dappBrowser: userSettings.dappBrowser)) {
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
              }
            case (.sellActions,.some),(.sellActions,.none):
              Link(destination:DappLink.openSeaUrl(nft:nft,dappBrowser: userSettings.dappBrowser)) {
                HStack {
                  Spacer()
                  Text("Sell")
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
              }
            }
          }
          .padding(.bottom,10)
          .padding(.top,currentBidPriceInWei == nil && currentAskPriceInWei == nil ? 10 : 0)
        }
      }
      
    }
    .onAppear {
      if let addr = NSUbiquitousKeyValueStore.default.string(forKey: CloudDefaultStorageKeys
                                                              .walletAddress.rawValue) {
        self.walletAddress = try? EthereumAddress(hex:addr,eip55: false)
      }
      
      let contract = collectionsFactory.getByAddress(nft.address)!.data.contract
      contract.tradeActions.map { tradeActions in
        self.tradeActions = TradeActionInfo(
          tradeActions: tradeActions,
          bidAsk: tradeActions.getBidAsk(nft.tokenId))
        
        self.tradeActions?.bidAsk
          .done {
            self.currentBidPriceInWei = $0.bid.map { $0.wei }
            self.currentAskPriceInWei = $0.ask.map { $0.wei }
          }
          .catch { print($0) }
      }
      contract.ownerOf(nft.tokenId)
        .done { ownerAddress in
          self.actionsState = self.tradeActions.flatMap { _ in
            walletAddress == ownerAddress ? .sellActions : .buyActions
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
      price:.eager(NFTPriceInfo(price:0,blockNumber: nil,type:.ask)),
      sample:SAMPLE_PUNKS[0],
      themeColor:SampleCollection.info.themeColor,
      themeLabelColor:SampleCollection.info.themeLabelColor,
      size:.normal,
      rarityRank:SampleCollection.info.rarityRanking,
      userWallet: UserWallet())
      .background(
        RoundedCorners(
          color: .secondarySystemBackground,
          tl: 20, tr: 20, bl: 0, br: 0))
    
  }
}
