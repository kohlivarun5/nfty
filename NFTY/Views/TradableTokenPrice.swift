//
//  TradableTokenPrice.swift
//  NFTY
//
//  Created by Varun Kohli on 7/6/21.
//

import SwiftUI

struct TradableTokenPrice: View {
  
  let price : TokenPriceType
  let color : Style
  
  var body: some View {
    HStack {
      TokenPrice(price:price,color:color,hideIcon:false)
        .padding(.trailing,5)
      Image(systemName: "chevron.right.circle.fill")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(height: 30)
        .foregroundColor(.secondaryLabel)
    }
    .padding(.top,8)
    .padding(.bottom,8)
    .padding(.leading)
    .padding(.trailing,10)
    .frame(minHeight:60)
    .background(RoundedCorners(color: .secondarySystemBackground, tl: 20, tr: 00, bl: 20, br: 0))
  }
}

struct TradableTokenPrice_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      Spacer()
      HStack {
        Spacer()
        
        TradableTokenPrice(
          price:.eager(NFTPriceInfo(wei:0,blockNumber: nil,type:.ask)),color:.label)
      }
      Spacer()
    }
  }
}
