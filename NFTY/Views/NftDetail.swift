//
//  NftDetail.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI
import PromiseKit
import URLImage
import BigInt

struct NftDetail: View {
  
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  
  var nft:NFT
  var price:TokenPriceType
  var samples:[String]
  var themeColor : Color
  var similarTokens : SimilarTokensGetter
  
  @State var tokens : [UInt]? = nil
  
  var body: some View {
    
    VStack {
      NftImage(nft:nft,samples:samples,themeColor:themeColor,size:.large)
        .frame(minHeight: 450)
      
      HStack() {
        VStack(alignment:.leading) {
          Text(nft.name)
            .font(.headline)
          Text("#\(nft.tokenId)")
            .font(.subheadline)
        }
        Spacer()
        TokenPrice(price:price,color:.label)
          .font(.title)
      }.padding()
      tokens.map { tokens in
        VStack {
          Divider()
          SimilarTokensView(info:collectionsFactory.getByAddress(nft.address)!.info,tokens:tokens)
        }
      }
    }
    .animation(.default)
    .navigationBarBackButtonHidden(true)
    .navigationBarItems(leading: Button(action: {presentationMode.wrappedValue.dismiss()}, label: { BackButton() }))
    .ignoresSafeArea(edges: .top)
    .onAppear {
      firstly {
        Promise.value(similarTokens(nft.tokenId))
      }.done(on:.main) { tokens in
        self.tokens = tokens
      }.catch { print($0) }
    }
  }
}

struct NftDetail_Previews: PreviewProvider {
  static var previews: some View {
    NftDetail(
      nft:SampleToken,
      price:.eager(NFTPriceInfo(price:0,blockNumber: nil)),
      samples:SAMPLE_PUNKS,
      themeColor:SampleCollection.info.themeColor,
      similarTokens:SampleCollection.info.similarTokens)
  }
}
