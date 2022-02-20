//
//  NFTNameIdRank.swift
//  NFTY
//
//  Created by Varun Kohli on 2/6/22.
//

import SwiftUI

struct NFTNameIdRank: View {
  
  
  private struct NFTNameIdRankImpl: View {
    let collection : Collection
    let nft : NFT
    let rank : UInt?
    let floorPrice : Double?
    
    var body: some View {
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
            .font(.footnote)
            .foregroundColor(.secondaryLabel)
        case (.none,.none):
          EmptyView()
        }
      }.padding([.top,.bottom],floorPrice == nil && rank == nil ? 2 : 0)
    }
  }
  
  let collection : Collection
  let nft : NFT
  let rank : UInt?
  let floorPrice : Double?
  
  let isSheet : Bool
  
  var body: some View {
    
    switch(isSheet,self.collection.contract.floorFetcher(collection)) {
    case (false,.none),(true,_):
      NFTNameIdRankImpl(
        collection: collection,
        nft: nft,
        rank: rank,
        floorPrice: floorPrice)
      
    case (false,.some):
      NavigationLink(
        destination:
          CollectionView(
            collection:collection,
            info:collection.info,
            loader: CompositeCollection.getLoader(collection: collection),
            page:.floor)
      ) {
        NFTNameIdRankImpl(
          collection: collection,
          nft: nft,
          rank: rank,
          floorPrice: floorPrice)
      }
      .buttonStyle(.plain)
    }
  }
}
