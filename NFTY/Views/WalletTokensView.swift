//
//  WalletTokensView.swift
//  NFTY
//
//  Created by Varun Kohli on 5/9/21.
//

import SwiftUI

import PromiseKit
import BigInt
import Web3

struct WalletOverview: View {
  
  @State var address : EthereumAddress
  @State private var balance : EthereumQuantity? = nil
  
  var body: some View {
    
    VStack {
      
      HStack() {
        VStack(alignment:.leading) {
          Text("Address")
            .font(.title3)
        }
        Spacer()
        Text(address.hex(eip55:true).trunc(length:30))
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
      Divider()
      VStack {
        HStack() {
          Text("Balance")
            .font(.title3)
          switch(balance) {
          case .none:
            Text("")
              .onAppear {
                firstly {
                  web3.eth.getBalance(address: address, block:.latest)
                }.done(on:.main) { balance in
                  self.balance = balance
                }.catch { print($0) }
              }
          case .some(let wei):
            UsdText(wei:wei.quantity)
              .font(.title3)
              .foregroundColor(.secondary)
          }
        }
        Divider()
      }
    }.padding()
  }
}

struct WalletTokensView: View {
  
  @ObservedObject var tokens : NftOwnerTokens
  @State private var selectedTokenId: UInt? = nil
  
  var body: some View {
    
    VStack {
      switch (tokens.state) {
      case .notLoaded,.loading:
        VStack {
          WalletOverview(address:tokens.ownerAddress)
          Spacer()
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .scaleEffect(2,anchor: .center)
            .padding()
            .onAppear {
              tokens.load()
            }
          Spacer()
        }
      case .loaded:
        if (tokens.tokens.isEmpty) {
          VStack {
            WalletOverview(address:tokens.ownerAddress)
            Spacer()
            Text("No Collectibles in Wallet")
              .font(.title)
              .foregroundColor(.secondary)
            Spacer()
          }
        } else {
          ScrollView {
            WalletOverview(address:tokens.ownerAddress)
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
  }
}

struct WalletTokensView_Previews: PreviewProvider {
    static var previews: some View {
      WalletTokensView(tokens:NftOwnerTokens(
                       ownerAddress:SAMPLE_WALLET_ADDRESS))
    }
}
