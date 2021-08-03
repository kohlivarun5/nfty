//
//  TokenListView.swift
//  NFTY
//
//  Created by Varun Kohli on 7/24/21.
//

import SwiftUI
import Web3

struct TokenListView: View {
  
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  
  let title : String
  let collection : Collection
  
  @ObservedObject var nfts : NftTokenList
  @State private var selectedTokenId: UInt? = nil
  
  init(title:String,collection:Collection,tokenIds:[UInt]) {
    self.title = title
    self.collection = collection
    self.nfts = NftTokenList(contract:collection.data.contract,tokenIds:tokenIds)
  }
  
    var body: some View {
      ScrollView {
        LazyVStack {
          ForEach(nfts.tokens.indices,id:\.self) { index in
            let nft = nfts.tokens[index];
            let info = collection.info
            let samples = [info.url1,info.url2,info.url3,info.url4];
            ZStack {
              RoundedImage(
                nft:nft.nft,
                price:.lazy(nft.indicativePriceWei),
                samples:samples,
                themeColor:info.themeColor,
                themeLabelColor:info.themeLabelColor,
                rarityRank:info.rarityRanking,
                width: .normal
              )
              .padding()
              .onTapGesture { self.selectedTokenId = nft.nft.tokenId }
              NavigationLink(destination: NftDetail(
                nft:nft.nft,
                price:.lazy(nft.indicativePriceWei),
                samples:samples,
                themeColor:info.themeColor,
                themeLabelColor:info.themeLabelColor,
                similarTokens:info.similarTokens,
                rarityRank:info.rarityRanking,
                hideOwnerLink:false
              ),tag:nft.nft.tokenId,selection:$selectedTokenId) {}
              .hidden()
            }
            .onAppear {
              DispatchQueue.global(qos:.userInitiated).async {
                self.nfts.next(currentIndex: index)
              }
            }
          }
        }.onAppear {
          nfts.loadMore {} // TODO
        }
      }
      .navigationBarTitle(title,displayMode: .inline)
      .navigationBarBackButtonHidden(true)
      .navigationBarItems(
        leading: Button(action: {presentationMode.wrappedValue.dismiss()}, label: { BackButton() }),
        trailing: Link(destination: self.collection.info.webLink) { Image(systemName: "safari") }
      )
    }
}

struct TokenListView_Previews: PreviewProvider {
    static var previews: some View {
      TokenListView(title:SampleCollection.info.name,collection:SampleCollection,tokenIds:[])
    }
}
