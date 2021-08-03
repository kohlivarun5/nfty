//
//  NftDetail.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI
import BigInt
import PromiseKit

struct NftDetail: View {
  
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  
  var nft:NFT
  var price:TokenPriceType
  var samples:[String]
  var themeColor : Color
  var themeLabelColor : Color
  var similarTokens : SimilarTokensGetter?
  var rarityRank : RarityRanking?
  var hideOwnerLink : Bool
  @State var rank : UInt? = nil
  
  @State var tokens : [UInt]? = nil
  
  @State var showTradeView : Bool = false
  
  var body: some View {
    
    VStack {
      
      ZStack {
        NftImage(
          nft:nft,
          samples:samples,
          themeColor:themeColor,
          themeLabelColor:themeLabelColor,
          size:.large
        )
        .frame(minHeight: 450)
        
        VStack(alignment: .leading) {
          Spacer()
          switch hideOwnerLink {
          case true:
            EmptyView()
          case false:
            HStack {
              OwnerProfileLinkButton(nft:nft,color:themeLabelColor)
              Spacer()
            }
          }
        }
        .padding()
      }
      
      HStack() {
        VStack(alignment:.leading) {
          Text(nft.name)
            .font(.headline)
          HStack {
            Text("#\(nft.tokenId)")
              .font(.subheadline)
            OpenSeaLink(nft:nft)
          }
          rank.map {
            Text("RarityRank: \($0)")
              .font(.footnote)
              .foregroundColor(.secondaryLabel)
          }
        }
        .padding(.leading)
        Spacer()
        
        switch(tokens) {
        case .none:
          TokenPrice(price:price,color:.label)
            .font(.title2)
            .padding()
        case .some:
          NavigationLink(
            destination:TokenTradeView(
              nft: nft,
              price:price,
              samples: samples,
              themeColor:themeColor,
              themeLabelColor:themeLabelColor,
              size: .small,
              rarityRank:rarityRank,
              isSheet:false),
            isActive:$showTradeView
          ) {
            Button(action: {
              UIImpactFeedbackGenerator(style:.soft)
                .impactOccurred()
              self.showTradeView = true
            }) {
              TradableTokenPrice(price:price,color:.label)
                .font(.title2)
                .padding(.top,8)
            }
          }
        }
      }
      tokens.map { tokens in
        VStack {
          ZStack {
            Divider()
            Text("Similar \(similarTokens?.label ?? "Tokens")")
              .font(.caption).italic()
              .foregroundColor(.secondaryLabel)
              .padding(.trailing)
              .padding(.leading)
              .background(Color.systemBackground)
          }
          SimilarTokensView(info:collectionsFactory.getByAddress(nft.address)!.info,tokens:tokens)
        }
      }
    }
    .navigationBarTitle("",displayMode:.large)
    .navigationBarBackButtonHidden(true)
    .navigationBarItems(
      leading:
        Button(action: {presentationMode.wrappedValue.dismiss()},
               label: { BackButton() }),
      trailing: Button(action: {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "nftygo.com"
        components.path = "/nft"
        components.queryItems = [
          URLQueryItem(name: "address", value: nft.address),
          URLQueryItem(name: "tokenId", value: String(nft.tokenId))
        ]
        guard let urlShare = components.url else { return }
        
        // https://stackoverflow.com/a/64962982
        let shareActivity = UIActivityViewController(activityItems: [urlShare], applicationActivities: nil)
        if let vc = UIApplication.shared.windows.first?.rootViewController {
          shareActivity.popoverPresentationController?.sourceView = vc.view
          //Setup share activity position on screen on bottom center
          shareActivity.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height, width: 0, height: 0)
          shareActivity.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.down
          vc.present(shareActivity, animated: true, completion: nil)
        }
      }, label: {
        Image(systemName: "arrowshape.turn.up.forward.circle")
          .foregroundColor(Color(UIColor.darkGray))
      })
    )
    
    .ignoresSafeArea(edges: .top)
    .onAppear {
      self.rank = rarityRank?.getRank(nft.tokenId)
      _ = similarTokens.map { similarTokens in
        Promise.value(similarTokens.get(nft.tokenId))
          .done(on:.main) { tokens in
            self.tokens = tokens
          }.catch { print($0) }
      }
    }
  }
}

struct NftDetail_Previews: PreviewProvider {
  static var previews: some View {
    NftDetail(
      nft:SampleToken,
      price:.eager(NFTPriceInfo(price:0,blockNumber: nil,type:.ask)),
      samples:SAMPLE_PUNKS,
      themeColor:SampleCollection.info.themeColor,
      themeLabelColor:SampleCollection.info.themeLabelColor,
      similarTokens:SampleCollection.info.similarTokens,
      rarityRank:SampleCollection.info.rarityRanking,
      hideOwnerLink:false)
  }
}
