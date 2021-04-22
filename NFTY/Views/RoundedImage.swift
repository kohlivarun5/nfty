//
//  RoundedImage.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI
import URLImage

struct RoundedImage: View {
    
  var nft:NFT
  var samples : [String]
  var themeColor : Color
    
    var body: some View {
        
        VStack {
          NftImage(url:nft.url,samples:samples,themeColor:themeColor)
            
            
            HStack {
                VStack(alignment:.leading) {
                    Text(nft.name)
                    Text("#\(nft.tokenId)")
                }
                Spacer()
              UsdText(eth:nft.eth)
            }
            .font(.subheadline)
            .padding()
        }
        
        .border(Color.secondary)
        .frame(width: 250.0)
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 25, style: .continuous).stroke(Color.gray, lineWidth: 1))
        .shadow(color:Color.primary,radius: 3)
        
    }
}

struct RoundedImage_Previews: PreviewProvider {
    static var previews: some View {
        Group {
          RoundedImage(nft:CrypotPunksNfts[10],samples:SAMPLE_PUNKS,themeColor:CryptoPunksCollection.info.themeColor)
        }
    }
}
