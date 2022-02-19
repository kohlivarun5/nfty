//
//  CollectionView.swift
//  NFTY
//
//  Created by Varun Kohli on 4/17/21.
//

import SwiftUI
import BigInt

struct VisualEffectView: UIViewRepresentable {
  var effect: UIVisualEffect?
  func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
  func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}

struct CollectionView: View {
  
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  @Environment(\.openURL) var openURL
  
  @StateObject var userSettings = UserSettings()
  
  let loader : CompositeRecentTradesObject.CollectionLoader
  
  private let collection : Collection
  private let info : CollectionInfo
  
  enum Page : Int {
    case recent
    case floor
    case vault
    case ranking
  }
  
  @State private var page : Page = .recent
  
  private func title(_ page:Page) -> String {
    switch(page) {
    case .recent:
      return "Recent"
    case .floor:
      return "Floor"
    case .vault:
      return "Vault"
    case .ranking:
      return "Ranking"
    }
  }
  
  init(loader:CompositeRecentTradesObject.CollectionLoader) {
    self.loader = loader
    self.collection = loader.collection
    self.info = collection.info
  }
  
  var body: some View {
    
    VStack(spacing:0) {
      
      switch(self.page) {
      case .recent:
        CollectionRecentView(loader:loader)
      case .floor:
        collection.contract.floorFetcher(collection).map {
          TokenListPagedView(
            collection: collection,
            nfts: TokensListPaged(fetcher:$0))
        }
      case .vault:
        collection.contract.vaultContract.map {
          NFTXVaultViewLazy(
            collection: collection,
            vaultContract: $0)
        }
      case .ranking:
        TokenListView(
          collection: self.collection,
          tokenIds:self.info.rarityRanking?.sortedTokenIds ?? []
        )
      }
      
      Picker(selection: Binding<Int>(
        get: { self.page.rawValue },
        set: { tag in
          withAnimation { // needed explicit for transitions
            self.page = Page(rawValue: tag)!
          }
        }
      ),label: Text(""))
      {
        Text(title(.recent)).tag(Page.recent.rawValue)
        
        collection.contract.floorFetcher(collection).map { _ in
          Text(title(.floor)).tag(Page.floor.rawValue)
        }
        
        collection.contract.vaultContract.map { _ in
          Text(title(.vault)).tag(Page.vault.rawValue)
        }
        
        self.info.rarityRanking.map { _ in
          Text(title(.ranking)).tag(Page.ranking.rawValue)
        }
      }
      .pickerStyle(SegmentedPickerStyle())
      .colorMultiply(.accentColor)
      .padding([.trailing,.leading])
      .padding(.top,5)
      .padding(.bottom,7)
      
    }
    .navigationBarTitle(info.name,displayMode: .inline)
    .navigationBarBackButtonHidden(true)
    .navigationBarItems(
      leading:Button(action: {presentationMode.wrappedValue.dismiss()}, label: { BackButton() }),
      trailing:Button(action: {
        openURL(
          self.collection.info.webLink
          ?? DappLink.openSeaUrl(address: self.collection.info.address, dappBrowser: userSettings.dappBrowser)
        )
      }) {
        Label("Website", systemImage: "safari")
      }
    )
    
  }
}

struct CollectionView_Previews: PreviewProvider {
  static var previews: some View {
    CollectionView(loader:CompositeCollection.loaders[0])
  }
}
