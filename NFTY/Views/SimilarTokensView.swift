//
//  SimilarTokensView.swift
//  NFTY
//
//  Created by Varun Kohli on 4/26/21.
//

import SwiftUI
import PromiseKit

struct SimilarTokensView: View {
  
  @State private var nfts : [NFT] = []
  @State private var action: String? = ""
  
  var info : CollectionInfo
  var tokens : [UInt]
  
  
  var body: some View {
    VStack {
      Divider()
      //Text("Similar Tokens").padding()
      ScrollView(.horizontal) {
        LazyHStack {
          ForEach(nfts.indices,id: \.self) { index in
            let nft = nfts[index];
            let samples = [info.url1,info.url2,info.url3,info.url4];
            ZStack {
              RoundedImage(nft:nft,samples:samples,themeColor:info.themeColor,width: .narrow)
                .scaleEffect(0.9)
                .onTapGesture {
                  //perform some tasks if needed before opening Destination view
                  self.action = String(nft.tokenId)
                }
              
              NavigationLink(destination: NftDetail(nft:nft,samples:samples,themeColor:info.themeColor),tag:String(nft.tokenId),selection:$action) {}
                .hidden()
            }
          }
        }
      }
    }.onAppear {
      tokens.forEach { tokenId in
        firstly {
          collectionsFactory.getByAddress(info.address)!.data.contract.getToken(tokenId)
        }.done { nft in
          nfts.append(nft)
        }
      }
    }
  }
}

struct SimilarTokensView_Previews: PreviewProvider {
  static var previews: some View {
    SimilarTokensView(info:CryptoPunksCollection.info,tokens:[])
  }
}