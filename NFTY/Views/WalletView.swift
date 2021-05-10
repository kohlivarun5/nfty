//
//  WalletView.swift
//  NFTY
//
//  Created by Varun Kohli on 5/9/21.
//

import SwiftUI

import PromiseKit
import BigInt

struct WalletView: View {
  
  @ObservedObject var tokens : NftOwnerTokens
  
  // private var firebase = FirebaseDb()
   
  @State private var showAddressSheet = false
  
  
  
  @State private var selectedTokenId: UInt? = nil
  @State private var isLoading = true
  
  var body: some View {
    
    VStack {
      switch (isLoading) {
      case true:
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle())
          .scaleEffect(3,anchor: .center)
          .padding()
          .onAppear {
            tokens.load {
              DispatchQueue.main.async {
                self.isLoading = false
              }
            }
          }
      case false:
        switch(tokens.tokens.count) {
        case 0:
          Text("No Collectibles in Wallet")
            .font(.title)
            .foregroundColor(.secondary)
        case _:
          ScrollView {
            LazyVStack {
              ForEach(tokens.tokens,id:\.id) { nft in
                let info = collectionsFactory.getByAddress(nft.nft.address)!.info;
                let samples = [info.url1,info.url2,info.url3,info.url4];
                ZStack {
                  RoundedImage(
                    nft:nft.nft,
                    price:.lazy(nft.indicativePriceWei),
                    samples:samples,
                    themeColor:info.themeColor,
                    width: .normal
                  )
                  .padding()
                  .onTapGesture {
                    //perform some tasks if needed before opening Destination view
                    self.selectedTokenId = nft.nft.tokenId
                  }
                  NavigationLink(destination: NftDetail(
                    nft:nft.nft,
                    price:.lazy(nft.indicativePriceWei),
                    samples:samples,
                    themeColor:info.themeColor,
                    similarTokens:info.similarTokens
                  ),tag:nft.nft.tokenId,selection:$selectedTokenId) {}
                  .hidden()
                }
              }
            }
            .animation(.default)
          }
        }
      }
    }
    .toolbar {
      Button(action: {
        self.showAddressSheet = true
      }) {
        Image(systemName:"plus.circle.fill")
      }
    }
    .sheet(isPresented: $showAddressSheet) {
      AddFavSheet()
    }
  }
}


struct WalletView_Previews: PreviewProvider {
    static var previews: some View {
      WalletView(
        tokens:NftOwnerTokens(
          ownerAddress:SAMPLE_WALLET_ADDRESS)
      )
    }
}
