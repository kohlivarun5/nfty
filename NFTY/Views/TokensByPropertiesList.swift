//
//  TokensByPropertiesList.swift
//  NFTY
//
//  Created by Varun Kohli on 8/29/21.
//

import SwiftUI
import Web3

struct TokensByPropertiesList: View {
  
  @Environment(\.colorScheme) var colorScheme
  
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  
  @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
  
  let properties : [SimilarTokensGetter.TokenAttributePercentile]
  let collection : Collection
  
  @EnvironmentObject var userWallet: UserWallet
  
  @ObservedObject var nfts : TokensByPropertiesObject
  
  @State private var selectedTokenId: UInt? = nil
  
  struct SheetSelection : Identifiable {
    let id : Int
  }
  @State private var sheetSelectedIndex: SheetSelection? = nil
  
  private func title(_ selectedProperties : [(name:String,value:String)]) -> String {
    switch(nfts.selectedProperties.count) {
    case 1:
      return "\(nfts.selectedProperties[0].name.capitalized): \(nfts.selectedProperties[0].value.capitalized)"
    default:
      return ""//Filtered"//\((collection.info.similarTokens?.label.map { " \($0)" }) ?? "")"
    }
    
  }
  
  var body: some View {
    VStack(spacing:0) {
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
              
              switch(nfts.tokenAsks[nft.nft.tokenId]?.ask?.wei) {
              case .none:
                EmptyView()
              case .some(let ask):
                VStack {
                  Spacer()
                  UsdEthVText(wei: ask, fontWeight: .semibold,alignment:.center)
                    .padding([.top,.bottom],2)
                    .padding([.leading,.trailing],20)
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? .label : .white)
                    .background(RoundedCorners(color:colorScheme == .dark ? .tertiarySystemBackground.opacity(0.75) : .secondary, tl: 5, tr: 5, bl: 5, br: 5))
                    .colorMultiply(.accentColor)
                    .shadow(radius: 5)
                }
                .padding(.bottom,11)
              }
              
              NavigationLink(destination: NftDetail(
                nft:nft.nft,
                price:.lazy(nft.indicativePriceWei),
                collection:collection,
                hideOwnerLink:false,
                selectedProperties:nfts.selectedProperties
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
      
      VStack(spacing:0) {
        HStack {
          Spacer()
          Text("Filters")
            .font(.caption).italic()
            .foregroundColor(.secondaryLabel)
          Spacer()
        }
        .padding([.top,.bottom],5)
        .background(RoundedCorners(color:.secondarySystemBackground, tl: 0, tr: 0, bl: 20, br: 20))
        
        TokenPropertiesGrid(properties: properties,collection:collection,selectedProperties:self.nfts.selectedProperties)
          .frame(maxHeight:135)
          .padding([.leading,.trailing])
      }
    }
    .sheet(item: $sheetSelectedIndex, onDismiss: { self.sheetSelectedIndex = nil }) {
      let nft = nfts.tokens[$0.id]
      let info = collection.info
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
