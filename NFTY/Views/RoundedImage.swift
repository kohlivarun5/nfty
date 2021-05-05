//
//  RoundedImage.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI
import URLImage
import BigInt
import PromiseKit

struct RoundedImage: View {
  
  var nft:NFT
  var price:TokenPriceType
  var samples : [String]
  var themeColor : Color
  
  enum Width {
    case normal
    case narrow
  }
  var width : Width
  
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
      return .small
    }
  }
  
  private func cornerRadius(_ width:Width) -> CGFloat {
    switch(width) {
    case .normal:
      return 25
    case .narrow:
      return 10
    }
  }
  
  var body: some View {
    
    VStack {
      NftImage(nft:nft,samples:samples,themeColor:themeColor,size:mediaSize(width))
      
      switch(width) {
      case .narrow:
        HStack {}
      case .normal:
        
        HStack {
          VStack(alignment:.leading) {
            Text(nft.name)
            Text("#\(nft.tokenId)")
          }
          Spacer()
          TokenPrice(price:price)
        }
        .font(.subheadline)
        .padding()
      }
    }
    
    .border(Color.secondary)
    .frame(width:frameWidth(width))
    .clipShape(RoundedRectangle(cornerRadius:cornerRadius(width), style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius:cornerRadius(width), style: .continuous).stroke(Color.gray, lineWidth: 1))
    .shadow(color:Color.primary,radius: 2)
    
  }
}

struct RoundedImage_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      RoundedImage(
        nft:SampleToken,
        price:.eager(NFTPriceInfo(price:0,blockNumber: nil)),
        samples:SAMPLE_PUNKS,
        themeColor:SampleCollection.info.themeColor,
        width: .normal)
    }
  }
}
