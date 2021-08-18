//
//  ExportNFTImageView.swift
//  NFTY
//
//  Created by Varun Kohli on 8/17/21.
//

import SwiftUI

struct ExportNFTImageView: View {
  
  var nft:NFT
  var samples:[String]
  var themeColor : Color
  var themeLabelColor : Color
  
  var body: some View {
    VStack {
      Spacer()
  
      NftImageView(
        nft:nft,
        samples:samples,
        themeColor:themeColor,
        themeLabelColor:themeLabelColor,
        size:.xlarge
      )
      Spacer()
    }
    .frame(maxWidth:.infinity,maxHeight:.infinity)
    .background(themeColor)
    
  }
}

struct ExportNFTImageView_Previews: PreviewProvider {
  static var previews: some View {
    ExportNFTImageView(
      nft:NFT(
        address: "0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb",
        tokenId: 340, name: "CryptoPunks",
        media:
          .asciiPunk(
            Media.AsciiPunkLazy(tokenId: 1, draw: { i in
              ObservablePromise(resolved:Media.AsciiPunk(unicode:"↑↑↓↓ ←→←→AB\n ┌────┐ │ ├┐ │┌ ┌\n └│ │ ╘ \n└┘ │ \n│ │╙\n─ │ │ │ └──┘ \n│ │ │\n │\n │"))
              
              
            }))),
      samples:SAMPLE_PUNKS,
      themeColor:.red,
      themeLabelColor:SampleCollection.info.themeLabelColor)
  }
}
