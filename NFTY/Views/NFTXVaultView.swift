//
//  NFTXVaultView.swift
//  NFTY
//
//  Created by Varun Kohli on 1/3/22.
//

import SwiftUI

struct NFTXVaultView: View {
  @Environment(\.colorScheme) var colorScheme
  
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  
  @EnvironmentObject var userWallet: UserWallet
  
  @State private var selectedTokenId: NFT.NftID? = nil
  
  struct SheetSelection : Identifiable {
    let id : Int
  }
  @State private var sheetSelectedIndex: SheetSelection? = nil
  
  let collection : Collection
  @StateObject var nfts : VaultTokensList
  
  
  var body: some View {
    VStack(spacing:0) {
      GeometryReader { metrics in
        ScrollView {
          LazyVGrid(
            columns: Array(
              repeating:GridItem(.flexible(maximum: UIDevice.current.userInterfaceIdiom == .pad ? RoundedImage.NormalSize+80 : 200)),
              count:UIDevice.current.userInterfaceIdiom == .pad
              ? Int(metrics.size.width / RoundedImage.NormalSize) - 1
              : 2)
          ) {
                ForEach(nfts.tokens.indices,id:\.self) { index in
                  let nft = nfts.tokens[index];
                  let info = collection.info
                  
                  ZStack {
                    
                    if (UIDevice.current.userInterfaceIdiom == .pad) {
                      
                      RoundedImage(
                        nft:nft.nft,
                        price:.lazy(nft.indicativePriceWei),
                        collection:collection,
                        width: .normal,
                        resolution: .normal
                      )
                        .shadow(color:.accentColor,radius:0)
                        .padding()
                        .onTapGesture {
                          //perform some tasks if needed before opening Destination view
                          self.selectedTokenId = nft.nft.id
                        }
                      
                    } else {
                      
                      NftImage(
                        nft:nft.nft,
                        sample:info.sample,
                        themeColor:info.themeColor,
                        themeLabelColor:info.themeLabelColor,
                        size:.small,
                        resolution:.normal,
                        favButton:.none
                      )
                        .clipShape(RoundedRectangle(cornerRadius:20, style: .continuous))
                        .shadow(color:.secondary,radius:5)
                        .padding(10)
                        .onTapGesture {
                          //perform some tasks if needed before opening Destination view
                          self.selectedTokenId = nft.nft.id
                        }
                        .onLongPressGesture(minimumDuration: 0.1) {
                          UIImpactFeedbackGenerator(style:.medium).impactOccurred()
                          self.sheetSelectedIndex = SheetSelection(id:index)
                        }
                    }
                    
                    NavigationLink(destination: NftDetail(
                      nft:nft.nft,
                      price:.lazy(nft.indicativePriceWei),
                      collection:collection,
                      hideOwnerLink:false,
                      selectedProperties:[]
                    ),tag:nft.nft.id,selection:$selectedTokenId) {}
                    .hidden()
                  }
                  .onAppear {
                    DispatchQueue.global(qos:.userInitiated).async {
                      self.nfts.next(currentIndex: index)
                    }
                  }
                }
              }.onAppear {
                nfts.loadMore {
                  print(self.nfts.tokens)
                } // TODO
              }
        }
      }
    }
    .sheet(item: $sheetSelectedIndex, onDismiss: { self.sheetSelectedIndex = nil }) {
      let nft = nfts.tokens[$0.id]
      TokenTradeView(
        nft: nft.nft,
        price:.lazy(nft.indicativePriceWei),
        collection:collection,
        userWallet:userWallet,
        isSheet:true)
        .ignoresSafeArea(edges:.bottom)
        .preferredColorScheme(.dark)
        .accentColor(.orange)
    }
  }
  
}


struct NFTXVaultViewLazy: View {
  let collection : Collection
  let vaultContract : CollectionVaultContract
  var body: some View {
    ObservedPromiseView(
      data: ObservablePromise(promise: vaultContract.allHoldings()),
      progress: {
        VStack {
          Spacer()
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .scaleEffect(3,anchor: .center)
            .padding()
          Spacer()
        }
      }) {
        NFTXVaultView(
          collection: collection,
          nfts: VaultTokensList(
            contract:collection.contract,
            allHoldings:$0,
            rankings:collection.info.rarityRanking
          )
        )
      }
  }
}
