//
//  TokenBuyView.swift
//  NFTY
//
//  Created by Varun Kohli on 7/25/21.
//

import SwiftUI
import BigInt
import Web3


struct TokenBuyView: View {
  
  let nft:NFT
  let price:TokenPriceType
  let sample:String
  let themeColor : Color
  let themeLabelColor : Color
  let size : NftImage.Size
  let rarityRank : RarityRanking?
  let tradeActions : TradeActionInfo
  let actions : TradeActionsInterface
  let walletProvider : WalletProvider
  
  let cornerRadius : CGFloat = 20
  let height : CGFloat = 100
  @State var rank : UInt? = nil
  
  @State private var eth : String = ""
  
  @State private var currentBidPrice : PriceUnit? = nil
  @State private var currentAskPrice : PriceUnit? = nil
  
  @State private var bidPriceInWei : BigUInt? = nil
  
  
  private func onBidPriceEntered() {
    bidPriceInWei = Double(eth).map { BigUInt($0 * 1e18) }
  }
  
  enum SpotState {
    case loading
    case localCurrency(Double)
    case unknown
  }
  
  @State private var spot : SpotState = .loading
  
  private func onSubmit() {
    guard let wei = bidPriceInWei else { return }
    actions.submitBid(tokenId: nft.tokenId, wei: wei, wallet:walletProvider)
      .done { print ($0) }
      .catch { print($0) }
  }
  
  private func onBuyNow(_ ask : PriceUnit) {
    switch(ask) {
    case .wei(let wei):
      actions.acceptOffer(tokenId: nft.tokenId, wei: wei, wallet:walletProvider)
        .done { print ($0) }
        .catch { print($0) }
    case .near:
      assertionFailure("Near not support for actions yet")
    }
  }
  
  var body: some View {
    VStack {
      
      HStack(alignment: .bottom) {
        
        NftImage(
          nft:nft,
          sample:sample,
          themeColor:themeColor,
          themeLabelColor:themeLabelColor,
          size:.xsmall,
          resolution:.hd,
          favButton:.none)
          .border(Color.secondary)
          .clipShape(RoundedRectangle(cornerRadius:20, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius:20, style: .continuous).stroke(Color.secondary, lineWidth: 2))
          .shadow(color:.accentColor,radius:0)
        
        Spacer()
        
        VStack {
          
          HStack {
            Text(nft.name)
              .font(.headline)
            Spacer()
          }
          HStack {
            Text("#\(String(nft.tokenId))")
              .font(.footnote)
            Spacer()
            
          }
          
          rank.map { rank in
            HStack {
              Text("RarityRank")
              Text("#\(rank)")
              Spacer()
            }
            .font(.footnote)
            .foregroundColor(.secondaryLabel)
          }
          
          HStack {
            Spacer()
            TokenPriceWithEth(price:price,color:.label)
              .font(.title2)
          }
          .padding(.top,2)
          
        }
        .padding(10)
        .background(Color.secondarySystemBackground)
        .cornerRadius(10)
        .padding(10)
        .padding(.top,10)
      }
      .padding(10)
      
      
      Form {
        Section(
          header: Text(""),
          content: {
            
            HStack {
              Text("Current Bid")
              Spacer()
              
              switch(currentBidPrice,spot) {
              case (.none,_):
                Text("N/A")
                  .foregroundColor(.secondary)
                  .font(.caption)
              case (.some,.loading):
                ProgressView()
              case (.some(.wei(let wei)),.localCurrency(let rate)):
                Text("\(UsdString(wei:wei,rate:rate)) (\(Text(PriceString(price:.wei(wei))))")
                
              case (.some(.near(let near)),_):
                Text(PriceString(price:.near(near)))
              case (.some(let price),.unknown):
                Text(PriceString(price:price))
              }
            }
            
            HStack {
              Text("Bid Amount (in ETH)")
              Spacer()
              TextField("Enter amount in ETH",text:$eth)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .onChange(of: eth) { val in self.onBidPriceEntered() }
              
            }
            
            HStack {
              Text("Bid Price")
              Spacer()
              switch(spot,bidPriceInWei) {
              case (.loading,_):
                ProgressView()
              case (.localCurrency(let rate),.some(let price)):
                Text(UsdString(wei:price,rate:rate))
                  .fontWeight(.semibold)
              case (.unknown,.some(let price)):
                Text(EthString(wei:price))
                  .fontWeight(.semibold)
              case (_,.none):
                Text(" ")
              }
            }
            
            Button(action: {
              UIImpactFeedbackGenerator(style:.soft)
                .impactOccurred()
              self.onSubmit()
            }) {
              HStack {
                Spacer()
                Text("Submit Bid")
                  .font(.callout)
                  .fontWeight(.bold)
                Spacer()
              }
            }
            .padding(10)
            .foregroundColor(bidPriceInWei == nil ? .white : .black)
            .background(bidPriceInWei == nil ? Color.gray : Color.accentColor)
            .cornerRadius(40)
            .padding(10)
            .disabled(bidPriceInWei == nil)
            
            
          }
        )
        
        Section(
          header: Text(""),
          content: {
            
            HStack {
              Text("Current Ask (in ETH)")
              Spacer()
              switch(currentAskPrice) {
              case .none:
                Text("N/A")
                  .foregroundColor(.secondary)
                  .font(.caption)
              case .some(let askPrice):
                Text(PriceString(price:askPrice))
              }
            }
            
            HStack {
              Text("Ask Price")
              Spacer()
              
              switch(currentAskPrice,spot) {
              case (.none,_):
                Text("N/A")
                  .foregroundColor(.secondary)
                  .font(.caption)
              case (.some,.loading):
                ProgressView()
                  .onAppear {
                    switch(self.spot) {
                    case .loading:
                      UserEthRate.getLiveRate()
                        .done(on:.main) { spot in
                          switch(spot) {
                          case .none:
                            self.spot = .unknown
                          case .some(let rate):
                            self.spot = .localCurrency(rate)
                          }
                        }.catch { print ($0) }
                    case .localCurrency,.unknown:
                      break
                    }
                  }
              case (.some(.wei(let wei)),.localCurrency(let rate)):
                Text(UsdString(wei:wei,rate:rate))
                  .fontWeight(.semibold)
              case (.some(.near(let near)),_):
                Text(PriceString(price:.near(near)))
                  .fontWeight(.semibold)
              case (.some(let price),.unknown):
                Text(PriceString(price:price))
                  .fontWeight(.semibold)
              }
            }
            
            switch (currentAskPrice) {
            case .some(let ask):
              HStack {
                Button(action: {
                  UIImpactFeedbackGenerator(style:.soft)
                    .impactOccurred()
                  self.onBuyNow(ask)
                }) {
                  HStack {
                    Spacer()
                    Text("Buy Now")
                      .font(.title3)
                      .fontWeight(.bold)
                    Spacer()
                  }
                }
                .padding(10)
                .foregroundColor(.black)
                .background(Color.green)
                .cornerRadius(40)
                .padding(10)
              }
            case .none:
              EmptyView()
            }
          }
        )
      }
      
    }
    
    .onAppear {
      
      switch(self.spot) {
      case .loading:
        UserEthRate.getLiveRate()
          .done(on:.main) { spot in
            switch(spot) {
            case .none:
              self.spot = .unknown
            case .some(let rate):
              self.spot = .localCurrency(rate)
            }
          }.catch { print ($0) }
      case .localCurrency,.unknown:
        break
      }
      
      self.rank = rarityRank?.getRank(nft.tokenId)
      self.tradeActions.bidAsk
        .done {
          self.currentAskPrice = $0.ask.map { $0.price }
          self.currentBidPrice = $0.bid.map { $0.price }
        }
        .catch { print($0) }
    }
  }
}

struct TokenBuyView_Previews: PreviewProvider {
  static var previews: some View {
    TokenBuyView(
      nft:SampleToken,
      price:.eager(NFTPriceInfo(price:.wei(123450),blockNumber: .none,type:.ask)),
      sample:SAMPLE_PUNKS[0],
      themeColor:SampleCollection.info.themeColor,
      themeLabelColor:SampleCollection.info.themeLabelColor,
      size:.normal,
      rarityRank:SampleCollection.info.rarityRanking,
      tradeActions: TradeActionInfo(
        tradeActions: SampleCollection.contract.tradeActions!,
        bidAsk:SampleCollection.contract.tradeActions!.getBidAsk(SampleToken.tokenId,nil)
      ),
      actions:SampleCollection.contract.tradeActions!.actions!,
      walletProvider:UserWallet().walletProvider!
    )
  }
}
