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
  let collection : Collection
  let size : NftImage.Size
  
  @ObservedObject var userWallet: UserWallet
  let isSheet : Bool
  
  let cornerRadius : CGFloat = 20
  let height : CGFloat = 240
  @State var rank : UInt? = nil
  
  @State var floorPrice : Double?
  
  var body: some View {
    VStack {
      
      VStack(spacing:0) {
        NftImage(
          nft:nft,
          sample:collection.info.sample,
          themeColor:collection.info.themeColor,
          themeLabelColor:collection.info.themeLabelColor,
          size:.small,
          resolution:.hd,
          favButton:.none
        )
          .frame(height:height)
          .padding(.top,isSheet ? 10 : 40)
          .padding(.bottom,10)
          .background(collection.info.themeColor)
        
        HStack {
          NFTNameIdRank(collection:collection, nft:nft,rank:rank,floorPrice:floorPrice,isSheet: isSheet)
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
          .padding([.trailing,.leading])
          .background(Color.systemBackground)
      }
      
      TradeEventsList(collection: collection, tokenId:nft.tokenId)
      
      TokenTradeActions(
        nft: nft,
        price:price,
        collection:collection,
        size: .small,
        userWallet:userWallet)
        .padding(.bottom,isSheet ? 12 : 0)
        .background(
          RoundedCorners(
            color: .secondarySystemBackground,
            tl: 20, tr: 20, bl: 0, br: 0))
        .animation(.default)
      
      
    }
    .font(.subheadline)
    .navigationBarTitle("",displayMode:.large)
    .navigationBarBackButtonHidden(true)
    .navigationBarItems(
      leading:
        Button(action: {presentationMode.wrappedValue.dismiss()},
               label: { BackButton() })
    )
    .ignoresSafeArea(edges: .top)
    .onAppear {
      self.rank = collection.info.rarityRanking?.getRank(nft.tokenId)
      collection.contract.indicativeFloor()
        .done(on:.main) { self.floorPrice = $0 }
        .catch { print($0) }
    }
  }
}

struct TokenTradeView_Previews: PreviewProvider {
  static var previews: some View {
    TokenTradeView(
      nft:SampleToken,
      price:.eager(NFTPriceInfo(price:0,blockNumber: nil,type:.ask)),
      collection:SampleCollection,
      size:.normal,
      userWallet:UserWallet(),
      isSheet:true)
  }
}
