//
//  TokenListPagedView.swift
//  NFTY
//
//  Created by Varun Kohli on 2/6/22.
//

import SwiftUI

struct TokenListPagedView: View {
  @Environment(\.colorScheme) var colorScheme
   
  @EnvironmentObject var userWallet: UserWallet
  
  @State private var selectedTokenId: NFT.NftID? = nil
  
  struct SheetSelection : Identifiable {
    let id : Int
  }
  @State private var sheetSelectedIndex: SheetSelection? = nil
  
  let collection : Collection
  @StateObject var nfts : TokensListPaged
  
  @State private var isLoading = true
  
  var body: some View {
    VStack(spacing:0) {
      
      switch(nfts.error,isLoading) {
      case (.some(let error),_):
        VStack(spacing:20) {
          Image(systemName: "exclamationmark.triangle")
            .font(.title)
            .foregroundColor(.accentColor)
          Text(error)
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
      case (.none,true):
        VStack {
          Spacer()
          ProgressView()
            .scaleEffect(2.0, anchor: .center)
          Spacer()
        }
        .onAppear {
          nfts.loadMore {
            self.isLoading = false
          }
        }
      case (.none,false):
        GeometryReader { metrics in
          ScrollView {
            LazyVGrid(
              columns: Array(
                repeating:GridItem(.flexible(maximum: UIDevice.current.userInterfaceIdiom == .pad ? RoundedImage.NormalSize+80 : 160)),
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
                    
                    VStack {
                      TokenPrice(price: TokenPriceType.lazy(nft.indicativePriceWei), color: .label,hideIcon:true)
                        .padding([.top,.bottom],2)
                        .padding([.leading,.trailing],20)
                        .font(.caption2)
                        .foregroundColor(colorScheme == .dark ? .label : .white)
                        .background(
                          RoundedCorners(
                            color:colorScheme == .dark
                            ? .tertiarySystemBackground.opacity(0.75)
                            : .secondary,
                            tl: 5, tr: 5, bl: 5, br: 5))
                        .colorMultiply(.accentColor)
                        .shadow(radius: 5)
                      Spacer()
                    }
                    .padding(.top,11)
                    
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
            }
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
