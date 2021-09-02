//
//  NFTExportView.swift
//  NFTY
//
//  Created by Varun Kohli on 9/1/21.
//

import SwiftUI

struct NFTExportView: View {
  var nft:NFT
  var sample:String
  var themeColor : Color
  var themeLabelColor : Color
  
  var body: some View {
    VStack {
      Spacer()
      
      NftImage(
        nft:nft,
        sample:sample,
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

struct NFTExportView_Previews: PreviewProvider {
    static var previews: some View {
        NFTExportView(nft: SampleToken, sample: SAMPLE_CCB[0], themeColor: .black, themeLabelColor: .white)
    }
}
