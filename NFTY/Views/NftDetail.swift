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
  @EnvironmentObject var userWallet: UserWallet
  
  let nft:NFT
  let price:TokenPriceType
  
  let collection : Collection
  
  let hideOwnerLink : Bool
  let selectedProperties : [(name:String,value:String)]
  @State var rank : UInt? = nil
  
  enum SimilarSectionPage : Int {
    case attributes = 0
    case similar = 1
  }
  @State var similarSectionPage : SimilarSectionPage = .attributes
  
  @State var tokens : [UInt]? = nil
  @State var properties : [SimilarTokensGetter.TokenAttributePercentile]? = nil
  
  @State var showTradeView : Bool = false
  
  enum ShareSheetPicker : Int,Identifiable {
    var id: Int { self.rawValue }
    
    case post
    case wallpaper
  }
  
  @State var sharePicker : ShareSheetPicker? = nil
  
  private func onShareLink() {
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
  }
  
  var body: some View {
    
    switch(collection.info.similarTokens) {
    case .none:
      TokenTradeView(
        nft: nft,
        price:price,
        collection:collection,
        userWallet:userWallet,
        isSheet:false)
    case .some:
      
      GeometryReader { metrics in
        VStack {
          
          ZStack {
            NftImage(
              nft:nft,
              sample:collection.info.sample,
              themeColor:collection.info.themeColor,
              themeLabelColor:collection.info.themeLabelColor,
              size:metrics.size.height < 700 ? .normal : .large,
              resolution:.hd,
              favButton:.bottomRight
            )
              .frame(minHeight: min(metrics.size.height-260,400))
            
            VStack(alignment: .leading) {
              Spacer()
              switch hideOwnerLink {
              case true:
                EmptyView()
              case false:
                HStack {
                  OwnerProfileLinkButton(nft:nft,color:collection.info.themeLabelColor, collection: collection)
                  Spacer()
                }
              }
            }
            .padding()
          }
          
          HStack {
            NFTNameIdRank(collection:collection, nft:nft,rank:rank,floorPrice:nil,isSheet:false)
              .padding(.leading)
            
            Spacer()
            
            NavigationLink(
              destination:TokenTradeView(
                nft: nft,
                price:price,
                collection:collection,
                userWallet:userWallet,
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
                  .padding([.top,.bottom],8)
              }
            }
          }
          
          HStack {
            Spacer()
              .frame(maxWidth:20)
            
            
            switch(tokens,properties) {
            case (.none,.none):
              EmptyView()
            case (.some(let tokens),.none):
              VStack(spacing:0) {
                ZStack {
                  Divider()
                  Text("Similar \(collection.info.similarTokens?.label ?? "Tokens")")
                    .font(.caption).italic()
                    .foregroundColor(.secondaryLabel)
                    .padding(.trailing)
                    .padding(.leading)
                    .background(Color.systemBackground)
                }
                SimilarTokensView(collection:collection,tokens:tokens)
              }
            case (.none,.some(let properties)):
              VStack(spacing:0) {
                ZStack {
                  Divider()
                  Text("Attributes")
                    .font(.caption).italic()
                    .foregroundColor(.secondaryLabel)
                    .padding(.trailing)
                    .padding(.leading)
                    .background(Color.systemBackground)
                }
                TokenPropertiesGrid(properties: properties,collection:collection,selectedProperties:selectedProperties)
                  .padding([.top,.bottom],5)
              }
            case (.some(let tokens),.some(let properties)):
              VStack(spacing:0) {
                
                ZStack {
                  
                  Picker(selection: Binding<Int>(
                    get: { self.similarSectionPage.rawValue },
                    set: { tag in
                      withAnimation { // needed explicit for transitions
                        self.similarSectionPage = SimilarSectionPage(rawValue: tag)!
                      }
                    }),
                         label: Text("")) {
                    Text("Attributes")
                      .tag(SimilarSectionPage.attributes.rawValue)
                    Text("Similar \(collection.info.similarTokens?.label ?? "Tokens")")
                      .tag(SimilarSectionPage.similar.rawValue)
                  }
                         .pickerStyle(SegmentedPickerStyle())
                         .colorMultiply(.accentColor)
                         .font(.caption)
                         .padding([.trailing,.leading])
                }
                
                switch(self.similarSectionPage) {
                case .similar:
                  SimilarTokensView(collection:collection,tokens:tokens)
                case .attributes:
                  TokenPropertiesGrid(properties: properties,collection:collection,selectedProperties:selectedProperties)
                    .padding([.top,.bottom],5)
                }
              }
            }
            
            Spacer()
              .frame(maxWidth:20)
          }
        }
      }
      .navigationBarTitle("",displayMode:.large)
      .navigationBarBackButtonHidden(true)
      .navigationBarItems(
        leading:
          Button(action: {presentationMode.wrappedValue.dismiss()},
                 label: { BackButton() }),
        trailing: Menu(
          content: {
            Button("Export", action: { self.sharePicker = .post })
            // Button("Create Wallpaper", action: { self.sharePicker = .wallpaper })
            Button("Share Via",action:onShareLink)
          },
          label: {
            Image(systemName: "arrowshape.turn.up.forward.circle")
              .foregroundColor(collection.info.themeLabelColor)
              .font(.title3)
          }
        )
      )
      .sheet(item: $sharePicker,
             onDismiss: { self.sharePicker = nil},
             content: { sharePicker in
        NFTExportView(
          nft: nft,
          sample:collection.info.sample,
          themeColor:collection.info.themeColor,
          themeLabelColor:collection.info.themeLabelColor
        )
        .themeStyle()
      })
      
      .ignoresSafeArea(edges: .top)
      .onAppear {
        self.rank = collection.info.rarityRanking?.getRank(nft.tokenId)
        self.tokens = collection.info.similarTokens?.get(nft.tokenId)
        self.properties = collection.info.similarTokens?.getProperties(nft.tokenId)
      }
    }
  }
}

struct NftDetail_Previews: PreviewProvider {
  static var previews: some View {
    NftDetail(
      nft:SampleToken,
      price:.eager(NFTPriceInfo(wei:0,blockNumber: nil,type:.ask)),
      collection:SampleCollection,
      hideOwnerLink:false,
      selectedProperties:[])
  }
}
