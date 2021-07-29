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
  let samples:[String]
  let themeColor : Color
  let themeLabelColor : Color
  let size : NftImage.Size
  let rarityRank : RarityRanking?
  
  @State private var walletAddress : EthereumAddress? = nil
  
  struct TradeActionInfo {
    let tradeActions : TokenTradeInterface
    let currentBidPriceInWei : Promise<BigUInt?>
    let currentAskPriceInWei : Promise<BigUInt?>
  }
  
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
    samples:[String],
    themeColor : Color,
    themeLabelColor : Color,
    size : NftImage.Size,
    rarityRank : RarityRanking?) {
    
    self.nft = nft
    self.price = price
    self.samples = samples
    self.themeColor = themeColor
    self.themeLabelColor = themeLabelColor
    self.size = size
    self.rarityRank = rarityRank
  }
  
  var body: some View {
    
    VStack {
      
      HStack(alignment:.center) {
        
        HStack {
          Spacer()
          VStack(alignment: .center) {
            Text("Bid")
              .italic()
              .padding(.bottom,1)
            switch(currentBidPriceInWei) {
            case .none:
              Text("N/A")
                .foregroundColor(.secondary)
                .font(.caption)
            case .some(let wei):
              UsdText(wei: wei,fontWeight:.semibold)
            }
          }
          Spacer()
        }
        Divider().frame(height:25)
        HStack {
          Spacer()
          VStack(alignment: .center) {
            Text("Ask")
              .italic()
              .padding(.bottom,1)
            switch(currentAskPriceInWei) {
            case .none:
              Text("N/A")
                .foregroundColor(.secondary)
                .font(.caption)
            case .some(let wei):
              UsdText(wei: wei,fontWeight:.semibold)
            }
          }
          Spacer()
        }
      }
      .padding(.top,10)
      .padding(.bottom,2)
      
      HStack {
        
        switch(actionsState,tradeActions) {
        case (.none,_),(_,.none):
          EmptyView()
        case (.some(let actions),.some(let tradeActions)):
          HStack {
            switch(actions) {
            case .buyActions:
              SheetButton(content: {
                HStack {
                  Spacer()
                  Text("Trade")
                    .foregroundColor(.black)
                    .font(.title2.weight(.bold))
                  Spacer()
                }
                .padding(10)
                .background(
                  RoundedCorners(
                    color: .flatOrange,
                    tl: 20, tr: 20, bl: 20, br: 20))
                .padding([.leading,.trailing],50)
              },sheetContent: {
                TokenBuyView(
                  nft: nft,
                  price:price,
                  samples: samples,
                  themeColor:themeColor,
                  themeLabelColor:themeLabelColor,
                  size: .xsmall,
                  rarityRank:rarityRank,
                  tradeActions: tradeActions.tradeActions
                )
              })
              
            case .sellActions:
              SheetButton(content: {
                HStack {
                  Spacer()
                  Text("Sell")
                    .foregroundColor(.black)
                    .font(.title2.weight(.bold))
                  Spacer()
                }
                .padding(10)
                .background(
                  RoundedCorners(
                    color: .flatGreen,
                    tl: 20, tr: 20, bl: 20, br: 20))
                .padding([.leading,.trailing],50)
              },sheetContent: {
                TokenSellView(
                  nft: nft,
                  price:price,
                  samples: samples,
                  themeColor:themeColor,
                  themeLabelColor:themeLabelColor,
                  size: .xsmall,
                  rarityRank:rarityRank,
                  tradeActions: tradeActions.tradeActions
                )
              })
            }
          }
          .padding(.bottom,10)
        /*
         
         .padding(.top,10)
         .background(Color.secondarySystemBackground)
         
         .background(
         RoundedCorners(
         color: .secondarySystemBackground,
         tl: 10, tr: 10, bl: 0, br: 0))*/
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
          currentBidPriceInWei: tradeActions.getBidPrice(nft.tokenId),
          currentAskPriceInWei: tradeActions.getAskPrice(nft.tokenId))
        
        self.tradeActions?.currentAskPriceInWei
          .done { self.currentAskPriceInWei = $0 }
        
        self.tradeActions?.currentBidPriceInWei
          .done { self.currentBidPriceInWei = $0 }
      }
      
      
      contract.ownerOf(nft.tokenId)
        .done { ownerAddress in
          self.actionsState = walletAddress == ownerAddress ? .sellActions : .buyActions
        }
    }
  }
}

struct TokenTradeActions_Previews: PreviewProvider {
  static var previews: some View {
    TokenTradeActions(
      nft: SampleToken,
      price:.eager(NFTPriceInfo(price:0,blockNumber: nil)),
      samples:SAMPLE_PUNKS,
      themeColor:SampleCollection.info.themeColor,
      themeLabelColor:SampleCollection.info.themeLabelColor,
      size:.normal,
      rarityRank:SampleCollection.info.rarityRanking)
      .background(
        RoundedCorners(
          color: .secondarySystemBackground,
          tl: 20, tr: 20, bl: 0, br: 0))
    
  }
}
