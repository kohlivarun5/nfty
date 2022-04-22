//
//  RoundedImage.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI
import BigInt

struct RoundedImage: View {
  @Environment(\.colorScheme) var colorScheme
  @EnvironmentObject var userWallet: UserWallet
  
  let nft:NFT
  let price:TokenPriceType
  let collection : Collection
  let rank : UInt?
  
  enum Width {
    case normal
    case narrow
  }
  let width : Width
  let resolution : NftImageResolution
  
  let action : Action?
  
  init(nft:NFT,
       price:TokenPriceType,
       collection:Collection,
       width:Width,
       resolution:NftImageResolution,
       action:Action? = nil)
  {
    
    self.nft = nft
    self.price = price
    self.collection = collection
    self.rank = collection.info.rarityRanking?.getRank(nft.tokenId)
    self.width = width
    self.resolution = resolution
    self.action = action
  }
  
  static let NormalSize = 250.0
  static let NarrowSize = 150.0
  
  private func frameWidth(_ width:Width) -> CGFloat {
    switch(width) {
    case .normal:
      return RoundedImage.NormalSize
    case .narrow:
      return RoundedImage.NarrowSize
    }
  }
  
  private func mediaSize(_ width:Width) -> NftImage.Size {
    switch(width) {
    case .normal:
      return .normal
    case .narrow:
      return .xsmall
    }
  }
  
  private func cornerRadius(_ width:Width) -> CGFloat {
    switch(width) {
    case .normal:
      return 20
    case .narrow:
      return 20
    }
  }
  
  var body: some View {
    
    VStack(spacing:0) {
      
      ZStack {
        
        NftImage(
          nft:nft,
          sample:collection.info.sample,
          themeColor:collection.info.themeColor,
          themeLabelColor:collection.info.themeLabelColor,
          size:mediaSize(width),
          resolution:resolution,
          favButton:.topRight)
        
        switch(action) {
        case .none:
          EmptyView()
        case .some(let action):
          VStack {
            Spacer()
            HStack {
              Spacer()
              ActionSummaryView(action: action)
              Spacer()
            }
            .padding([.top,.bottom],2)
            .font(.footnote)
            .modifier(PriceOverlay())
            .padding([.leading,.trailing],15)
          }
          .padding(.bottom,2)
        }
        
      }
      
      switch(width) {
      case .narrow:
        HStack {}
      case .normal:
        HStack(alignment:.center) {
          NFTNameIdRank(collection:collection, nft:nft,rank:rank,floorPrice:nil,isSheet: false)
            .padding(.leading)
          
          Spacer()
          
          
          NavigationLink(
            destination:TokenTradeView(
              nft: nft,
              price:price,
              collection:collection,
              userWallet:userWallet,
              isSheet:false)
          ) {
            TokenPrice(price:price,color:.label,hideIcon:false)
          }
          .padding(.leading,5)
          .padding(.trailing,5)
          .padding([.top,.bottom],5)
          .background(RoundedCorners(color: .secondarySystemBackground, tl: 10, tr: 10, bl: 10, br: 10))
          .padding(.trailing,10)
        }
        .font(.subheadline)
        .padding([.top,.bottom],10)
        .background(Color.systemBackground)
        
      }
    }
    
    .border(Color.secondary)
    .frame(width:frameWidth(width))
    .clipShape(RoundedRectangle(cornerRadius:cornerRadius(width), style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius:cornerRadius(width), style: .continuous).stroke(Color.secondary, lineWidth: 2))
  }
}

struct RoundedImage_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      RoundedImage(
        nft:SampleToken,
        price:.eager(NFTPriceInfo(wei:0,blockNumber: nil,type:.ask)),
        collection:SampleCollection,
        width: .normal,
        resolution: .hd)
    }
  }
}
