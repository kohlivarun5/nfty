//
//  NftUrlView.swift
//  NFTY
//
//  Created by Varun Kohli on 5/25/21.
//

import SwiftUI

struct NftUrlView: View {
  
  let nft : NFTWithLazyPrice
  
  let collection : Collection
  
  init(collection:Collection, tokenId:UInt) {
    self.nft = collection.contract.getToken(tokenId)
    self.collection = collection
  }
  
  var body: some View {
    NftDetail(
      nft:nft.nft,
      price:.lazy(nft.indicativePrice),
      collection:collection,
      hideOwnerLink:true,selectedProperties:[]
    )
  }
}
