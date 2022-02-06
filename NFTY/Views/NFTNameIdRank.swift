//
//  NFTNameIdRank.swift
//  NFTY
//
//  Created by Varun Kohli on 2/6/22.
//

import SwiftUI

struct NFTNameIdRank: View {
  let nft : NFT
  let rank : UInt?
  
  var body: some View {
    VStack(alignment:.leading) {
      Text(nft.name)
      HStack {
        Text("#\(nft.tokenId)")
        DappLink(destination: DappLink.openSeaPath(nft: nft))
      }
      .font(.footnote)
      
      rank.map {
        Text( "RarityRank: \($0)")
          .font(.caption2)
          .foregroundColor(.secondaryLabel)
      }
      
    }
    .padding(.leading)
  }
}
