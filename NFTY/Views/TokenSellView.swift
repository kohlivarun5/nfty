//
//  TokenSellView.swift
//  NFTY
//
//  Created by Varun Kohli on 7/25/21.
//

import SwiftUI
import BigInt
import Web3


struct TokenSellView: View {
  let nft:NFT
  let price:TokenPriceType
  let sample:String
  let themeColor : Color
  let themeLabelColor : Color
  let size : NftImage.Size
  let rarityRank : RarityRanking?
  let tradeActions : TokenTradeInterface
  
  let cornerRadius : CGFloat = 20
  let height : CGFloat = 100
  @State var rank : UInt? = nil
  
  @State private var eth : String = ""
  
  @State private var priceInWei : BigUInt? = nil
  
  private func onPriceEntered() {
    priceInWei = Double(eth).map { BigUInt($0 * 1e18) }
  }
  
  enum SpotState {
    case loading
    case localCurrency(Double)
    case unknown
  }
  
  @State private var spot : SpotState = .loading
  
  private func onSubmit() {
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
      
      ZStack {
        Divider()
        Text("Set Ask Price in ETH")
          .font(.title3).italic()
          .foregroundColor(.secondaryLabel)
          .padding(10)
          .background(Color.systemBackground)
      }
      
      TextField("ETH",text:$eth)
        .font(.title3)
        .keyboardType(.decimalPad)
        .multilineTextAlignment(.center)
        .introspectTextField { textField in
          textField.becomeFirstResponder()
        }
        .onChange(of: eth) { val in self.onPriceEntered() }
      
      ZStack{
        Divider()
        Text("Sale Price")
          .font(.title3).italic()
          .foregroundColor(.secondaryLabel)
          .padding(10)
          .background(Color.systemBackground)
      }
      
      VStack {
        
        switch(spot,priceInWei) {
        case (.loading,_):
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
        case (.localCurrency(let rate),.some(let price)):
          Text(UsdString(wei:price,rate:rate))
        case (.unknown,.some(let price)):
          Text(EthString(wei:price))
        case (_,.none):
          Text(" ")
        }
        
        
        HStack {
          Button(action: {
            UIImpactFeedbackGenerator(style:.soft)
              .impactOccurred()
            self.onSubmit()
          }) {
            HStack {
              Spacer()
              Text("Start Sale")
              Spacer()
            }
            .padding()
            .foregroundColor(priceInWei == nil ? .white : .black)
            .background(priceInWei == nil ? Color.gray : Color.green)
            .cornerRadius(40)
            .padding(.leading)
            .padding(.trailing)
            .padding(.top,10)
          }
          .disabled(priceInWei == nil)
        }
        .foregroundColor(.black)
      }.font(.title2.weight(.bold))
      
      Text("NFTYgo deducts 0.3% as protocol fees when sale settles")
        .padding(.bottom,5)
        .padding(.top,5)
        .font(.footnote)
        .foregroundColor(.secondary)
      
      Spacer()
      
      
    }
    .navigationBarTitle("",displayMode:.large)
    .onAppear {
      self.rank = rarityRank?.getRank(nft.tokenId)
    }
  }
}

struct TokenSellView_Previews: PreviewProvider {
    static var previews: some View {
      TokenSellView(
        nft:SampleToken,
        price:.eager(NFTPriceInfo(wei:123450,blockNumber: nil,type:.ask)),
        sample:SAMPLE_PUNKS[0],
        themeColor:SampleCollection.info.themeColor,
        themeLabelColor:SampleCollection.info.themeLabelColor,
        size:.normal,
        rarityRank:SampleCollection.info.rarityRanking,
        tradeActions: SampleCollection.contract.tradeActions!
      )
    }
}
