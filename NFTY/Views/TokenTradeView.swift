//
//  TokenTradeView.swift
//  NFTY
//
//  Created by Varun Kohli on 7/7/21.
//

import SwiftUI

struct TokenTradeView: View {
  
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  
  @State var uiTabarController: UITabBarController?
  
  
  let nft:NFT
  let price:TokenPriceType
  let samples:[String]
  let themeColor : Color
  let themeLabelColor : Color
  let size : NftImage.Size
  let rarityRank : RarityRankGetter
  
  let cornerRadius : CGFloat = 20
  let height : CGFloat = 160
  @State var rank : UInt? = nil
  
  var body: some View {
    VStack {
      VStack {
        NftImage(
          nft:nft,
          samples:samples,
          themeColor:themeColor,
          themeLabelColor:themeLabelColor,
          size:.small
        )
        .frame(height:height)
        .padding(.top,20)
        .background(themeColor)
        
        HStack {
          VStack(alignment: .leading) {
            Text(nft.name)
              .font(.headline)
            Text("#\(nft.tokenId)")
              .font(.subheadline)
            rank.map {
              Text("RarityRank: \($0)")
                .font(.footnote)
            }
          }
          Spacer()
          TokenPrice(price:price,color:.label)
        }
        .padding()
        .background(
          RoundedCorners(
            color: .secondarySystemBackground,
            tl: 0, tr: 0, bl: 20, br: 20))
        .foregroundColor(.label)
      }
      
      Spacer()
    }
    .animation(.default)
    .navigationBarTitle("",displayMode:.large)
    .navigationBarBackButtonHidden(true)
    .navigationBarItems(
      leading:
        Button(action: {presentationMode.wrappedValue.dismiss()},
               label: { BackButton() })
    )
    .ignoresSafeArea(edges: .top)
    .introspectTabBarController { (UITabBarController) in
      UITabBarController.tabBar.isHidden = true
      uiTabarController = UITabBarController
    }.onDisappear{
      uiTabarController?.tabBar.isHidden = false
    }
    .animation(.default)
    .onAppear {
      self.rank = rarityRank(nft.tokenId)
    }
  }
}

struct TokenTradeView_Previews: PreviewProvider {
  static var previews: some View {
    TokenTradeView(
      nft:SampleToken,
      price:.eager(NFTPriceInfo(price:0,blockNumber: nil)),
      samples:SAMPLE_PUNKS,
      themeColor:SampleCollection.info.themeColor,
      themeLabelColor:SampleCollection.info.themeLabelColor,
      size:.normal,
      rarityRank:SampleCollection.info.rarityRank)
  }
}
