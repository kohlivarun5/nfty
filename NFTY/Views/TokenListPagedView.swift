//
//  TokenListPagedView.swift
//  NFTY
//
//  Created by Varun Kohli on 2/6/22.
//

import SwiftUI

struct TokenListPagedView: View {
  @Environment(\.colorScheme) var colorScheme
  
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  
  @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
  
  @EnvironmentObject var userWallet: UserWallet
  
  @State private var selectedTokenId: UInt? = nil
  
  struct SheetSelection : Identifiable {
    let id : Int
  }
  @State private var sheetSelectedIndex: SheetSelection? = nil
  
  let collection : Collection
  @ObservedObject var nfts : TokensListPaged
  
  
  var body: some View {
    VStack(spacing:0) {
      
      switch(nfts.error,nfts.tokens.count) {
      case (.some(let error),_):
        VStack(spacing:20) {
          Image(systemName: "exclamationmark.triangle")
            .font(.title)
            .foregroundColor(.accentColor)
          Text(error)
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
      case (.none,0):
        ProgressView()
          .scaleEffect(2.0, anchor: .center)
          .onAppear {
            nfts.loadMore {
              print(self.nfts.tokens)
            } // TODO
          }
      case (.none,_):
        
        ScrollView {
          LazyVGrid(
            columns: Array(
              repeating:GridItem(.flexible(maximum:160)),
              count:horizontalSizeClass == .some(.compact) ? 2 : 3)) {
                ForEach(nfts.tokens.indices,id:\.self) { index in
                  let nft = nfts.tokens[index];
                  let info = collection.info
                  
                  ZStack {
                    
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
                        self.selectedTokenId = nft.nft.tokenId
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
                    
                    NavigationLink(destination: NftDetail(
                      nft:nft.nft,
                      price:.lazy(nft.indicativePriceWei),
                      collection:collection,
                      hideOwnerLink:false,
                      selectedProperties:[]
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
        size: .xsmall,
        userWallet:userWallet,
        isSheet:true)
        .ignoresSafeArea(edges:.bottom)
        .preferredColorScheme(.dark)
        .accentColor(.orange)
    }
    .navigationBarTitle(collection.info.name,displayMode: .inline)
    .navigationBarBackButtonHidden(true)
    .navigationBarItems(
      leading:
        Button(action: {presentationMode.wrappedValue.dismiss()},
               label: { BackButton() })
    )
  }
}

/*
struct TokenListPagedView_Previews: PreviewProvider {
    static var previews: some View {
        TokenListPagedView(
        )
    }
}
 */
