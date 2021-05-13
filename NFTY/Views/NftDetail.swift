//
//  NftDetail.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI
import URLImage
import BigInt
import PromiseKit

struct NftDetail: View {
  
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  
  var nft:NFT
  var price:TokenPriceType
  var samples:[String]
  var themeColor : Color
  var themeLabelColor : Color
  var similarTokens : SimilarTokensGetter
  
  @State var tokens : [UInt]? = nil
  
  var body: some View {
    
    VStack {
      
      ZStack {
        NftImage(nft:nft,samples:samples,themeColor:themeColor,themeLabelColor:themeLabelColor,size:.large)
          .frame(minHeight: 450)
        VStack(alignment: .leading) {
          Spacer()
          HStack {
            OwnerProfileLinkButton(nft:nft,color:themeLabelColor)
            Spacer()
          }
        }
        .padding()
      }
      
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
      Promise.value(similarTokens(nft.tokenId))
        .done(on:.main) { tokens in
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
      themeLabelColor:SampleCollection.info.themeLabelColor,
      similarTokens:SampleCollection.info.similarTokens)
  }
}
