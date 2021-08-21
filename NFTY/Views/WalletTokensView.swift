//
//  WalletTokensView.swift
//  NFTY
//
//  Created by Varun Kohli on 5/9/21.
//

import SwiftUI

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
        AddressLabelWithShare(address:address.hex(eip55:true),maxLen:25)
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
                web3.eth.getBalance(address: address, block:.latest)
                  .done(on:.main) { balance in
                    self.balance = balance
                  }.catch { print($0) }
              }
          case .some(let wei):
            UsdText(wei:wei.quantity,fontWeight: .semibold)
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
            
            LazyVGrid(columns: [GridItem(.flexible()),GridItem(.flexible())],pinnedViews: [.sectionHeaders]) {
              
              ForEach(
                Dictionary(
                  grouping:tokens.tokens,
                  by: { nft in nft.nft.address }).sorted(by: { $0.key > $1.key }),
                id:\.key) { address,tokens in
                
                let info = collectionsFactory.getByAddress(address)!.info;
                
                
                ForEach(tokens,id:\.id) { nft in
                  
                  ZStack {
                    RoundedImage(
                      nft:nft.nft,
                      price:.lazy(nft.indicativePriceWei),
                      sample:info.sample,
                      themeColor:info.themeColor,
                      themeLabelColor:info.themeLabelColor,
                      rarityRank: info.rarityRanking,
                      width:.narrow
                    )
                    .padding(10)
                    .onTapGesture {
                      //perform some tasks if needed before opening Destination view
                      self.selectedTokenId = nft.nft.tokenId
                    }
                    NavigationLink(destination: NftDetail(
                      nft:nft.nft,
                      price:.lazy(nft.indicativePriceWei),
                      sample:info.sample,
                      themeColor:info.themeColor,
                      themeLabelColor:info.themeLabelColor,
                      similarTokens:info.similarTokens,
                      rarityRank:info.rarityRanking,
                      hideOwnerLink:false
                    ),tag:nft.nft.tokenId,selection:$selectedTokenId) {}
                    .hidden()
                  }
                }
              }
              
              
            }
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
