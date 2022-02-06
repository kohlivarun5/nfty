//
//  NFTNameIdRank.swift
//  NFTY
//
//  Created by Varun Kohli on 2/6/22.
//

import SwiftUI

struct NFTNameIdRank: View {
  let collection : Collection
  let nft : NFT
  let rank : UInt?
  let floorPrice : Double?
  
  let isSheet : Bool
  
  @State var showFloorView : Bool = false
  
  var body: some View {
    
    switch(isSheet,self.collection.contract.floorFetcher) {
    case (false,.none),(true,_):
      VStack(alignment:.leading) {
        Text(nft.name)
        HStack {
          Text("#\(nft.tokenId)")
          DappLink(destination: DappLink.openSeaPath(nft: nft))
        }
        .font(.footnote)
        
        switch(floorPrice,rank) {
        case (.some(let floorPrice),_):
          Text("Floor Price: \(ethFormatter.string(for:floorPrice)!)")
            .font(.footnote)
            .foregroundColor(.secondaryLabel)
            .animation(.default)
        case (_,.some(let rank)):
          Text( "RarityRank: \(rank)")
            .font(.caption2)
            .foregroundColor(.secondaryLabel)
        case (.none,.none):
          EmptyView()
        }
     
      }
      .padding(.leading)
      
      
    case (false,.some(let fetcher)):
      NavigationLink(
        destination:TokenListPagedView(
          collection: collection,
          nfts: TokensListPaged(fetcher:fetcher)
        ),
        isActive:$showFloorView
      ) {
        
        VStack(alignment:.leading) {
          Text(nft.name)
          HStack {
            Text("#\(nft.tokenId)")
            Image(systemName: "arrow.right.square.fill")
              .foregroundColor(.tertiaryLabel)
          }
          .font(.footnote)
          
          rank.map {
            Text( "RarityRank: \($0)")
              .font(.caption2)
              .foregroundColor(.secondaryLabel)
          }
          
        }
        .padding(.leading)
        .onTapGesture {
          self.showFloorView = true
        }
        
      }
    }
  }
}
