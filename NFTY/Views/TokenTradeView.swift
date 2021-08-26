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
  let sample:String
  let themeColor : Color
  let themeLabelColor : Color
  let size : NftImage.Size
  let rarityRank : RarityRanking?
  @ObservedObject var userWallet: UserWallet
  let isSheet : Bool
  
  let cornerRadius : CGFloat = 20
  let height : CGFloat = 240
  @State var rank : UInt? = nil
  
  var body: some View {
    VStack {
      
      VStack(spacing:0) {
        NftImage(
          nft:nft,
          sample:sample,
          themeColor:themeColor,
          themeLabelColor:themeLabelColor,
          size:.small
        )
        .frame(height:height)
        .padding(.top,isSheet ? 10 : 30)
        .padding(.bottom,10)
        .background(themeColor)
        
        HStack {
          VStack(alignment: .leading) {
            Text(nft.name)
              .font(.headline)
            HStack {
              Text("#\(nft.tokenId)")
              DappLink(destination: DappLink.openSeaPath(nft: nft))
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
            .font(.title2)
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
      
      TokenTradeActions(
        nft: nft,
        price:price,
        sample: sample,
        themeColor:themeColor,
        themeLabelColor:themeLabelColor,
        size: .small,
        rarityRank:rarityRank,
        userWallet:userWallet)
        .padding(.bottom,isSheet ? 12 : 0)
        .background(
          RoundedCorners(
            color: .secondarySystemBackground,
            tl: 20, tr: 20, bl: 0, br: 0))
        .animation(.default)
      
      
    }
    .navigationBarTitle("",displayMode:.large)
    .navigationBarBackButtonHidden(true)
    .navigationBarItems(
      leading:
        Button(action: {presentationMode.wrappedValue.dismiss()},
               label: { BackButton() })
    )
    .ignoresSafeArea(edges: .top)
    .onAppear {
      self.rank = rarityRank?.getRank(nft.tokenId)
    }
  }
}

struct TokenTradeView_Previews: PreviewProvider {
  static var previews: some View {
    TokenTradeView(
      nft:SampleToken,
      price:.eager(NFTPriceInfo(price:0,blockNumber: nil,type:.ask)),
      sample:SAMPLE_PUNKS[0],
      themeColor:SampleCollection.info.themeColor,
      themeLabelColor:SampleCollection.info.themeLabelColor,
      size:.normal,
      rarityRank:SampleCollection.info.rarityRanking,
      userWallet:UserWallet(),
      isSheet:true)
  }
}
