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
            DappLink.DappLinkView(destination: DappLink.openSeaPath(nft: nft),label : {
              Image(systemName: "arrow.up.right.square.fill")
              .foregroundColor(.tertiaryLabel)
            })
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
        }
      }
    }
  }
  
  let collection : Collection
  let nft : NFT
  let rank : UInt?
  let floorPrice : PriceUnit?
  
  let isSheet : Bool
  
  var body: some View {
    switch isSheet {
    case true:
      NFTNameIdRankImpl(
        collection: collection,
        nft: nft,
        rank: rank,
        floorPrice: floorPrice,
        isExternalLink:true)
      
    case false:
      NavigationLink(
        destination:
          CollectionView(
            collection:collection,
            info:collection.info,
            loader: CompositeCollection.getLoader(collection: collection),
            page:.recent)
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
