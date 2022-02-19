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
  
  var body: some View {
    
    switch(isSheet,self.collection.contract.floorFetcher(collection)) {
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
          Text("")
            .font(.footnote)
        }
     
      }
      
    case (false,.some):
      NavigationLink(
        destination:
          CollectionView(
            collection:collection,
            info:collection.info,
            loader: CompositeCollection.getLoader(collection: collection),
            page:.floor)
      ) {
        
        VStack(alignment:.leading) {
          Text(nft.name)
          HStack {
            Text("#\(nft.tokenId)")
            Image(systemName: "arrow.right.square.fill")
              .foregroundColor(.tertiaryLabel)
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
      }
      .buttonStyle(.plain)
    }
  }
}
