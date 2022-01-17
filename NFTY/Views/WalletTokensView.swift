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
            UsdEthHText(wei:wei.quantity,fontWeight: .semibold)
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
  @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
  
  @EnvironmentObject var userWallet: UserWallet
  
  @ObservedObject var tokens : NftOwnerTokens
  @State private var selectedTokenId: UInt? = nil
  
  @State private var sheetSelectedIndex: NftOwnerTokens.Token? = nil
  
  
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
            
            LazyVGrid(
              columns: Array(
                repeating:GridItem(.flexible(maximum:160)),
                count:horizontalSizeClass == .some(.compact) ? 2 : 3),
              pinnedViews: [.sectionHeaders])
            {
              
              ForEach(
                Dictionary(
                  grouping:tokens.tokens,
                  by: { return $0.collection.info.address }).sorted(by: { $0.key > $1.key }),
                id:\.key) { (_,tokens) in
                  
                  let collection = tokens.first!.collection
                  
                  Section(header: WalletTokensCollectionHeader(collection:collection)) {
                    
                    ForEach(tokens,id:\.nft.id) { token in
                      
                      ZStack {
                        
                        NftImage(
                          nft:token.nft.nft,
                          sample:token.collection.info.sample,
                          themeColor:token.collection.info.themeColor,
                          themeLabelColor:token.collection.info.themeLabelColor,
                          size:.small,
                          favButton:.none
                        )
                          .clipShape(RoundedRectangle(cornerRadius:20, style: .continuous))
                          .shadow(color:.secondary,radius:5)
                          .padding(10)
                          .onTapGesture {
                            //perform some tasks if needed before opening Destination view
                            self.selectedTokenId = token.nft.nft.tokenId
                          }
                          .onLongPressGesture(minimumDuration: 0.1) {
                            UIImpactFeedbackGenerator(style:.medium).impactOccurred()
                            self.sheetSelectedIndex = token.nft
                          }
                        NavigationLink(destination: NftDetail(
                          nft:token.nft.nft,
                          price:.lazy(token.nft.indicativePriceWei),
                          collection:token.collection,
                          hideOwnerLink:false,
                          selectedProperties:[]
                        ),tag:token.nft.nft.tokenId,selection:$selectedTokenId) {}
                        .hidden()
                      }
                    }
                  }
                }
            }
          }
          .sheet(item: $sheetSelectedIndex, onDismiss: { self.sheetSelectedIndex = nil }) { token in
            TokenTradeView(
              nft: token.nft.nft,
              price:.lazy(token.nft.indicativePriceWei),
              collection:token.collection,
              size: .xsmall,
              userWallet:userWallet,
              isSheet:true)
              .ignoresSafeArea(edges:.bottom)
              .preferredColorScheme(.dark)
              .accentColor(.orange)
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
