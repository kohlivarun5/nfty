//
//  SimilarTokensView.swift
//  NFTY
//
//  Created by Varun Kohli on 4/26/21.
//

import SwiftUI

struct SimilarTokensView: View {
  
  @State private var nfts : [NFTWithLazyPrice] = []
  @State private var action: String? = ""
  
  var collection : Collection
  var tokens : [UInt]
  
  var body: some View {
    GeometryReader { metrics in
      ScrollView(.horizontal) {
        LazyHStack {
          ForEachWithIndex(nfts) { index,nft in
            ZStack {
              NftImage(
                nft:nft.nft,
                sample:collection.info.sample,
                themeColor:collection.info.themeColor,
                themeLabelColor:collection.info.themeLabelColor,
                size:metrics.size.height < 700 ? .xxsmall : .xsmall,
                resolution:.hd,
                favButton:.none
              )
              .frame(maxHeight:200)
              .clipShape(RoundedRectangle(cornerRadius:20, style: .continuous))
              .shadow(color:.secondary,radius:5)
              .padding([.top,.bottom],12)
              .padding([.leading,.trailing],8)
              //.scaleEffect(0.9)
              .onTapGesture {
                //perform some tasks if needed before opening Destination view
                self.action = String(nft.nft.tokenId)
                
              }
              
              NavigationLink(destination: NftDetail(
                nft:nft.nft,
                price:.lazy(nft.indicativePrice),
                collection:collection,
                hideOwnerLink:false,
                selectedProperties:[]
              ),tag:String(nft.nft.tokenId),selection:$action) {}
              .hidden()
            }
          }
        }
      }
      .onAppear {
        DispatchQueue.global(qos:.userInteractive).async {
          tokens.forEach { tokenId in
            let nft = collection.contract.getToken(tokenId)
            nfts.append(nft)
          }
        }
      }
    }
  }
}

struct SimilarTokensView_Previews: PreviewProvider {
  static var previews: some View {
    SimilarTokensView(collection:SampleCollection,tokens:[])
  }
}
