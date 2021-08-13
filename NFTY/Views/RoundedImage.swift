//
//  RoundedImage.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI
import BigInt

struct RoundedImage: View {
  
  var nft:NFT
  var price:TokenPriceType
  var samples : [String]
  var themeColor : Color
  var themeLabelColor : Color
  var rarityRank : RarityRanking?
  var rank : UInt?
  
  enum Width {
    case normal
    case narrow
  }
  var width : Width
  
  init(nft:NFT,
       price:TokenPriceType,
       samples : [String],
       themeColor : Color,
       themeLabelColor : Color,
       rarityRank : RarityRanking?,
       width:Width)
  {
    
    self.nft = nft
    self.price = price
    self.samples = samples
    self.themeColor = themeColor
    self.themeLabelColor = themeLabelColor
    self.rarityRank = rarityRank
    self.rank = rarityRank?.getRank(nft.tokenId)
    self.width = width
  }
  
  private func frameWidth(_ width:Width) -> CGFloat {
    switch(width) {
    case .normal:
      return 250.0
    case .narrow:
      return 150.0
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
      return 10
    }
  }
  
  var body: some View {
    
    VStack(spacing:0) {
      NftImage(nft:nft,samples:samples,themeColor:themeColor,themeLabelColor:themeLabelColor,size:mediaSize(width))
      
      switch(width) {
      case .narrow:
        HStack {}
      case .normal:
        HStack {
          VStack(alignment:.leading) {
            Text(nft.name)
            HStack {
              Text("#\(nft.tokenId)")
              OpenSeaLink(nft:nft)
            }
            .font(.footnote)
            
            rank.map {
              Text("RarityRank: \($0)")
                .font(.caption2)
                .foregroundColor(.secondaryLabel)
            }
          }
          .padding(.leading)
          
          Spacer()
          SheetButton(content: {
            TokenPrice(price:price,color:.label)
          },sheetContent: {
            TokenTradeView(
              nft: nft,
              price:price,
              samples: samples,
              themeColor:themeColor,
              themeLabelColor:themeLabelColor,
              size: .xsmall,
              rarityRank:rarityRank,
              isSheet:true)
              .ignoresSafeArea(edges:.bottom)
          })
          .padding(.leading,5)
          .padding(.trailing,5)
          .padding([.top,.bottom],5)
          .background(RoundedCorners(color: .secondarySystemBackground, tl: 10, tr: 10, bl: 10, br: 10))
          .padding(.bottom,5)
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
      RoundedRectangle(cornerRadius:cornerRadius(width), style: .continuous).stroke(Color.gray, lineWidth: 2))
  }
}

struct RoundedImage_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      RoundedImage(
        nft:SampleToken,
        price:.eager(NFTPriceInfo(price:0,blockNumber: nil,type:.ask)),
        samples:SAMPLE_PUNKS,
        themeColor:SampleCollection.info.themeColor,
        themeLabelColor:SampleCollection.info.themeLabelColor,
        rarityRank: SampleCollection.info.rarityRanking,
        width: .normal)
    }
  }
}
