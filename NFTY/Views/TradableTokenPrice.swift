//
//  TradableTokenPrice.swift
//  NFTY
//
//  Created by Varun Kohli on 7/6/21.
//

import SwiftUI

struct RoundedCorners: View {
  var color: Color
  var tl: CGFloat = 0.0
  var tr: CGFloat = 0.0
  var bl: CGFloat = 0.0
  var br: CGFloat = 0.0
  
  var body: some View {
    GeometryReader { geometry in
      Path { path in
        
        let w = geometry.size.width
        let h = geometry.size.height
        
        // Make sure we do not exceed the size of the rectangle
        let tr = min(min(self.tr, h/2), w/2)
        let tl = min(min(self.tl, h/2), w/2)
        let bl = min(min(self.bl, h/2), w/2)
        let br = min(min(self.br, h/2), w/2)
        
        path.move(to: CGPoint(x: w / 2.0, y: 0))
        path.addLine(to: CGPoint(x: w - tr, y: 0))
        path.addArc(center: CGPoint(x: w - tr, y: tr), radius: tr, startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)
        path.addLine(to: CGPoint(x: w, y: h - br))
        path.addArc(center: CGPoint(x: w - br, y: h - br), radius: br, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)
        path.addLine(to: CGPoint(x: bl, y: h))
        path.addArc(center: CGPoint(x: bl, y: h - bl), radius: bl, startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)
        path.addLine(to: CGPoint(x: 0, y: tl))
        path.addArc(center: CGPoint(x: tl, y: tl), radius: tl, startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
      }
      .fill(self.color)
    }
  }
}

struct TradableTokenPrice: View {
  
  let price : TokenPriceType
  let color : Style
  
  var body: some View {
    HStack {
      TokenPrice(price:price,color:color)
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
          price:.eager(NFTPriceInfo(price:0,blockNumber: nil)),color:.label)
      }
      Spacer()
    }
  }
}
