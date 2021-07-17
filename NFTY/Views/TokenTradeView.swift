//
//  TokenTradeView.swift
//  NFTY
//
//  Created by Varun Kohli on 7/7/21.
//

import SwiftUI
import BigInt
import Web3

struct TokenTradeView: View {
  
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  
  let nft:NFT
  let price:TokenPriceType
  let samples:[String]
  let themeColor : Color
  let themeLabelColor : Color
  let size : NftImage.Size
  let rarityRank : RarityRankGetter
  
  let cornerRadius : CGFloat = 20
  let height : CGFloat = 300
  @State var rank : UInt? = nil
  
  var body: some View {
    VStack {
      
      VStack(spacing:0) {
        NftImage(
          nft:nft,
          samples:samples,
          themeColor:themeColor,
          themeLabelColor:themeLabelColor,
          size:.medium
        )
        .frame(height:height)
        .padding(.top,20)
        .background(themeColor)
        
        HStack {
          VStack(alignment: .leading) {
            Text(nft.name)
              .font(.headline)
            HStack {
              Text("#\(nft.tokenId)")
              OpenSeaLink(nft:nft)
            }
            .font(.footnote)
            rank.map {
              Text("RarityRank: \($0)")
                .font(.footnote)
                .foregroundColor(.secondaryLabel)
            }
          }
          Spacer()
          TokenPrice(price:price,color:.label)
            .font(.title)
        }
        .padding()
        .background(
          RoundedCorners(
            color: .secondarySystemBackground,
            tl: 0, tr: 0, bl: 20, br: 20))
        .foregroundColor(.label)
      }
      
      ZStack {
        Divider()
        Text("History")
          .font(.caption).italic()
          .foregroundColor(.secondaryLabel)
          .padding(.trailing)
          .padding(.leading)
          .background(Color.systemBackground)
      }
      
      TradeEventsList(contract: nft.address, tokenId:nft.tokenId)
      
      HStack {
        Button(action: {
          UIImpactFeedbackGenerator(style:.soft)
            .impactOccurred()
        }) {
          HStack {
            Spacer()
            Text("Enter Bid")
              .foregroundColor(.black)
              .font(.title2.weight(.bold))
            Spacer()
          }
          .padding()
          .background(
            RoundedCorners(
              color: .flatOrange,
              tl: 0, tr: 20, bl: 0, br: 20))
        }
        
        SheetButton(content: {
          HStack {
            Spacer()
            Text("Sell")
              .foregroundColor(.black)
              .font(.title2.weight(.bold))
            Spacer()
          }
          .padding()
          .background(
            RoundedCorners(
              color: .flatGreen,
              tl: 20, tr: 0, bl: 20, br: 0))
        },sheetContent: {
          BidOfferView(
            nft: nft,
            price:price,
            samples: samples,
            themeColor:themeColor,
            themeLabelColor:themeLabelColor,
            size: .small,
            rarityRank:rarityRank)
        })
      }
      .padding(.bottom,10)
      .padding(.top,10)
      .background(
        RoundedCorners(
          color: .secondarySystemBackground,
          tl: 10, tr: 10, bl: 0, br: 0))
      
    }
    .animation(.default)
    .navigationBarTitle("",displayMode:.large)
    .navigationBarBackButtonHidden(true)
    .navigationBarItems(
      leading:
        Button(action: {presentationMode.wrappedValue.dismiss()},
               label: { BackButton() })
    )
    .ignoresSafeArea(edges: .top)
    .onAppear {
      self.rank = rarityRank(nft.tokenId)
    }
  }
}

struct TokenTradeView_Previews: PreviewProvider {
  static var previews: some View {
    TokenTradeView(
      nft:SampleToken,
      price:.eager(NFTPriceInfo(price:0,blockNumber: nil)),
      samples:SAMPLE_PUNKS,
      themeColor:SampleCollection.info.themeColor,
      themeLabelColor:SampleCollection.info.themeLabelColor,
      size:.normal,
      rarityRank:SampleCollection.info.rarityRank)
  }
}
