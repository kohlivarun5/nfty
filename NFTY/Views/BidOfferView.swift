//
//  BidOfferView.swift
//  NFTY
//
//  Created by Varun Kohli on 7/16/21.
//

import SwiftUI
import BigInt
import Web3

struct BidOfferView: View {
  
  let nft:NFT
  let price:TokenPriceType
  let samples:[String]
  let themeColor : Color
  let themeLabelColor : Color
  let size : NftImage.Size
  let rarityRank : RarityRankGetter
  
  let cornerRadius : CGFloat = 20
  let height : CGFloat = 100
  @State var rank : UInt? = nil
  
  @State private var eth : String = ""
  
  @State private var priceInWei : BigUInt? = nil
  
  private func onPriceEntered() {
    priceInWei = Double(eth).map { BigUInt($0 * 1e18) }
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
      
      ZStack {
        Divider()
        Text("Set Price in ETH")
          .font(.title3).italic()
          .foregroundColor(.secondaryLabel)
          .padding()
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
          .padding()
          .background(Color.systemBackground)
      }
      
      VStack {
        
        switch (priceInWei) {
        case .some(let price):
          UsdText(wei:price)
        case .none:
          Text(" ")
        }
      
        HStack {
          Button(action: {
            UIImpactFeedbackGenerator(style:.soft)
              .impactOccurred()
          }) {
            HStack {
              Spacer()
              Text("Submit Sale")
              Spacer()
            }
            .padding()
            .foregroundColor(.white)
            .background(priceInWei == nil ? Color.gray : Color.green)
            .cornerRadius(40)
            .padding()
          }
          .disabled(priceInWei == nil)
        }
        .foregroundColor(.black)
      }.font(.title2.weight(.bold))
      
      //Spacer()
      
      
    }
    .animation(.default)
    .navigationBarTitle("",displayMode:.large)
    .onAppear {
      self.rank = rarityRank(nft.tokenId)
    }
  }
}

struct BidOfferView_Previews: PreviewProvider {
  static var previews: some View {
    BidOfferView(
      nft:SampleToken,
      price:.eager(NFTPriceInfo(price:123450,blockNumber: nil)),
      samples:SAMPLE_PUNKS,
      themeColor:SampleCollection.info.themeColor,
      themeLabelColor:SampleCollection.info.themeLabelColor,
      size:.normal,
      rarityRank:SampleCollection.info.rarityRank)
  }
}
