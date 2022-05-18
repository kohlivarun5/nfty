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
  
  @State var account : UserAccount
  @State private var balance : EthereumQuantity? = nil
  
  var body: some View {
    
    VStack {
      
      account.ethAddress.map { address in
        
        HStack() {
          VStack(alignment:.leading) {
            Text("ETH")
              .font(.title3)
              .bold()
          }
          Spacer()
          AddressLabelWithShare(address:address.hex(eip55:true),maxLen:25)
        }
      }
      
      account.nearAccount.map { _ in
        Divider()
      }
      
      account.nearAccount.map { account in
        HStack() {
          VStack(alignment:.leading) {
            Text("NEAR")
              .font(.title3)
              .bold()
          }
          Spacer()
          AddressLabel(address: account, maxLen: 25)
        }
      }
      
      Divider()
      account.ethAddress.map { address in
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
              UsdEthHText(price:.wei(wei.quantity),fontWeight: .semibold)
                .font(.title3)
                .foregroundColor(.secondary)
            }
          }
          Divider()
        }
      }
      
    }.padding()
  }
}

struct WalletTokensView: View {
  
  @EnvironmentObject var userWallet: UserWallet
  
  @ObservedObject var tokens : NftOwnerTokens
  @State private var selectedTokenId: BigUInt? = nil
  
  @State private var sheetSelectedIndex: NFTToken? = nil
  
  
  var body: some View {
    
    VStack {
      switch (tokens.state) {
      case .notLoaded,.loading:
        VStack {
          Spacer()
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .scaleEffect(2,anchor: .center)
            .padding()
            .onAppear {
              DispatchQueue.main.async {
                tokens.load({})
              }
            }
          Spacer()
        }
      case .loaded,.loadingMore:
        if (tokens.tokens.isEmpty) {
          VStack {
            Spacer()
            Text("No Collectibles in Wallet")
              .font(.title)
              .foregroundColor(.secondary)
            Spacer()
          }
        } else {
          GeometryReader { metrics in
            ScrollView {
              LazyVGrid(
                columns: Array(
                  repeating:GridItem(.flexible(maximum: UIDevice.current.userInterfaceIdiom == .pad ? RoundedImage.NormalSize+80 : min(200,(metrics.size.width - 40) / Double(2)))),
                  count:UIDevice.current.userInterfaceIdiom == .pad
                  ? Int(metrics.size.width / RoundedImage.NormalSize) - 1
                  : 2),
                pinnedViews: [.sectionHeaders])
              {
                
                ForEach(tokens.tokens.indices,id:\.self) { index in
                  
                  let (collection,tokens) = tokens.tokens[index];
                  Section(header: WalletTokensCollectionHeader(collection:collection)) {
                    
                    ForEach(tokens,id:\.nft.nft.id) { token in
                      
                      ZStack {
                        
                        if (UIDevice.current.userInterfaceIdiom == .pad) {
                          
                          RoundedImage(
                            nft:token.nft.nft,
                            price:.lazy(token.nft.indicativePrice),
                            collection:collection,
                            width: .normal,
                            resolution: .normal
                          )
                            .shadow(color:.accentColor,radius:0)
                            .padding()
                            .onTapGesture {
                              //perform some tasks if needed before opening Destination view
                              self.selectedTokenId = token.nft.nft.tokenId
                            }
                          
                        } else {
                            
                          NftImage(
                            nft:token.nft.nft,
                            sample:token.collection.info.sample,
                            themeColor:token.collection.info.themeColor,
                            themeLabelColor:token.collection.info.themeLabelColor,
                            size:.small,
                            resolution:.normal,
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
                              self.sheetSelectedIndex = token
                            }
                        }
                        NavigationLink(destination: NftDetail(
                          nft:token.nft.nft,
                          price:.lazy(token.nft.indicativePrice),
                          collection:token.collection,
                          hideOwnerLink:false,
                          selectedProperties:[]
                        ),tag:token.nft.nft.tokenId,selection:$selectedTokenId) {}
                        .hidden()
                      }
                    }
                  }
                  .onAppear {
                    DispatchQueue.global(qos:.userInitiated).async {
                      self.tokens.loadMore(index)
                    }
                  }
                }
              }
            }
          }
          .sheet(item: $sheetSelectedIndex, onDismiss: { self.sheetSelectedIndex = nil }) { token in
            TokenTradeView(
              nft: token.nft.nft,
              price:.lazy(token.nft.indicativePrice),
              collection:token.collection,
              userWallet:userWallet,
              isSheet:true)
              .ignoresSafeArea(edges:.bottom)
              .themeStyle()
          }
        }
      }
    }
  }
}
