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
  let samples:[String]
  let themeColor : Color
  let themeLabelColor : Color
  let size : NftImage.Size
  let rarityRank : RarityRanking?
  let tradeActions : TokenTradeInterface
  
  let cornerRadius : CGFloat = 20
  let height : CGFloat = 100
  @State var rank : UInt? = nil
  
  @State private var eth : String = ""
  
  @State private var bidPriceInWei : BigUInt? = nil
  @State private var askPriceInWei : BigUInt? = nil
  
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
    print(eth)
    print(bidPriceInWei)
    print(spot)
  }
  
  var body: some View {
    VStack {
      
      HStack(alignment: .bottom) {
        
        RoundedImage(
          nft:nft,
          price:price,
          samples:samples,
          themeColor:themeColor,
          themeLabelColor:themeLabelColor,
          rarityRank: rarityRank,
          width: .narrow
        )
        
        VStack {
          
          HStack {
            Text(nft.name)
              .font(.headline)
            Spacer()
          }
          HStack {
            Text("#\(nft.tokenId)")
              .font(.footnote)
            Spacer()
            
          }
          
          rank.map { rank in
            HStack {
              Text("RarityRank")
              Spacer()
              Text("#\(rank)")
            }
            .font(.footnote)
            .foregroundColor(.secondaryLabel)
          }
          
        }
        .padding()
      }
      .padding()
      
      
      Form {
        Section(
          header: Text("Bid"),
          footer: HStack {
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
            .background(bidPriceInWei == nil ? Color.gray : Color.flatOrange)
            .cornerRadius(40)
            .padding(10)
            .disabled(bidPriceInWei == nil)
          },
          content: {
            HStack {
              Text("Enter Bid (in ETH)")
              Spacer()
              TextField("",text:$eth)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .onChange(of: eth) { val in self.onBidPriceEntered() }
              
            }
            
            HStack {
              Text("Fiat Price")
              Spacer()
              switch(spot,bidPriceInWei) {
              case (.loading,_):
                ProgressView()
                  .onAppear {
                    switch(self.spot) {
                    case .loading:
                      EthSpot.getLiveRate()
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
              case (.localCurrency(let rate),.some(let price)):
                Text(currencyFormatter.string(for:((Double(price) / 1e18) * rate))!)
              case (.unknown,.some(let price)):
                Text(ethFormatter.string(for:(Double(price) / 1e18))!)
              case (_,.none):
                Text(" ")
              }
            }
          }
        )
        
        Section {} // Spacer
        
        switch(askPriceInWei) {
        case .none:
          Section {}
        case .some(let askPriceInWei):
          Section(
            header: Text("Ask"),
            footer: HStack {
              Button(action: {
                UIImpactFeedbackGenerator(style:.soft)
                  .impactOccurred()
                self.onSubmit()
              }) {
                HStack {
                  Spacer()
                  Text("Buy Now")
                    .font(.callout)
                    .fontWeight(.bold)
                  Spacer()
                }
              }
              .padding(10)
              .foregroundColor(.black)
              .background(Color.flatGreen)
              .cornerRadius(40)
              .padding(10)
            },
            content: {
              HStack {
                Text("Current Ask")
                Spacer()
                Text(ethFormatter.string(for:(Double(0) / 1e18))!)
              }
              
              HStack {
                Text("Fiat Price")
                Spacer()
                switch(spot) {
                case .loading:
                  ProgressView()
                    .onAppear {
                      switch(self.spot) {
                      case .loading:
                        EthSpot.getLiveRate()
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
                case .localCurrency(let rate):
                  Text(currencyFormatter.string(for:((Double(askPriceInWei) / 1e18) * rate))!)
                case .unknown:
                  Text(ethFormatter.string(for:(Double(askPriceInWei) / 1e18))!)
                }
              }
            }
          )
        }
      }
      
    }
    .onAppear {
      self.rank = rarityRank?.getRank(nft.tokenId)
      self.tradeActions.getAskPrice(nft.tokenId)
        .done { self.askPriceInWei = $0 }
    }
  }
}

struct TokenBuyView_Previews: PreviewProvider {
  static var previews: some View {
    TokenBuyView(
      nft:SampleToken,
      price:.eager(NFTPriceInfo(price:123450,blockNumber: nil)),
      samples:SAMPLE_PUNKS,
      themeColor:SampleCollection.info.themeColor,
      themeLabelColor:SampleCollection.info.themeLabelColor,
      size:.normal,
      rarityRank:SampleCollection.info.rarityRanking,
      tradeActions: SampleCollection.data.contract.tradeActions!
    )
  }
}
