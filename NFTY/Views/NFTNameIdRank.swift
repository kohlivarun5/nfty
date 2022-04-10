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
    let floorPrice : PriceUnit?
    let isExternalLink : Bool
    
    var body: some View {
      VStack(alignment:.leading) {
        Text(nft.name)
        HStack {
          Text("#\(String(nft.tokenId))")
          switch(isExternalLink) {
          case true:
            DappLink(destination: DappLink.openSeaPath(nft: nft))
          case false:
            Image(systemName: "arrow.right.square.fill")
              .foregroundColor(.tertiaryLabel)
          }
        }
        .font(.footnote)
        
        HStack {
          switch(floorPrice,rank) {
          case (.some(let floorPrice),_):
            Text("Floor Price: \(PriceString(price:floorPrice))")
              .font(.footnote)
              .foregroundColor(.secondaryLabel)
              .animation(.default)
          case (_,.some(let rank)):
            Text("RarityRank: \(rank)")
              .font(.footnote)
              .foregroundColor(.secondaryLabel)
          case (.none,.none):
            Text("")
              .font(.footnote)
          }
        }//.animation(.default)
      }
    }
  }
  
  let collection : Collection
  let nft : NFT
  let rank : UInt?
  let floorPrice : PriceUnit?
  
  let isSheet : Bool
  
  var body: some View {
    
    switch(isSheet,self.collection.contract.floorFetcher(collection)) {
    case (false,.none),(true,_):
      NFTNameIdRankImpl(
        collection: collection,
        nft: nft,
        rank: rank,
        floorPrice: floorPrice,
        isExternalLink:true)
      
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
          floorPrice: floorPrice,
          isExternalLink:false)
      }
      .buttonStyle(.plain)
    }
  }
}
