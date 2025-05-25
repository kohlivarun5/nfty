//
//  WalletTokensSelector.swift
//  NFTY
//
//  Created by Varun Kohli on 5/31/22.
//

import SwiftUI

import BigInt
import Web3

struct WalletTokensSelector: View {
  
  @StateObject var tokens : NftOwnerTokens
  let enableNavLinks : Bool
  let redactPrice : Bool
  @State private var selectedTokenId: BigUInt? = nil
  
  @Binding var selectedToken: NFTTokenEquatable?
  
  
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
                columns: RoundedImage.columnsFlexIcons(width: metrics.size.width),
                pinnedViews: [.sectionHeaders])
              {
                
                ForEach(tokens.tokens.indices,id:\.self) { index in
                  
                  let (collection,tokens) = tokens.tokens[index];
                  Section(header: WalletTokensCollectionHeader(collection:collection)) {
                    
                    ForEach(tokens,id:\.nft.nft.id) { token in
                      
                      ZStack {
                        
                        if (RoundedImage.isIpadStyle(width:metrics.size.width)) {
                          
                          RoundedImage(
                            nft:token.nft.nft,
                            price:.lazy(token.nft.indicativePrice),
                            collection:collection,
                            width: .normal,
                            resolution: .normal,
                            redactPrice:redactPrice
                          )
                          .shadow(color:.accentColor,radius:0)
                          .padding()
                          .onTapGesture {
                            //perform some tasks if needed before opening Destination view
                            if (enableNavLinks) { self.selectedTokenId = token.nft.nft.tokenId }
                            else { self.selectedToken = NFTTokenEquatable(token:token) }
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
                            if (enableNavLinks) { self.selectedTokenId = token.nft.nft.tokenId }
                            else { self.selectedToken = NFTTokenEquatable(token:token) }
                          }
                          .onLongPressGesture(minimumDuration: 0.1) {
                            UIImpactFeedbackGenerator(style:.medium).impactOccurred()
                            self.selectedToken = NFTTokenEquatable(token:token)
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
        }
      }
    }
  }
}
