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
    self.nft = collection.data.contract.getToken(tokenId)
    self.collection = collection
  }
  
  var body: some View {
    NftDetail(
      nft:nft.nft,
      price:.lazy(nft.indicativePriceWei),
      collection:collection,
      hideOwnerLink:true,selectedProperties:[]
    )
  }
}

struct NftUrlView_Previews: PreviewProvider {
  static var previews: some View {
    NftUrlView(collection:SampleCollection,tokenId: SampleToken.tokenId)
  }
}
