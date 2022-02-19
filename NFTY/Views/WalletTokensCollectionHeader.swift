//
//  WalletTokensCollectionHeader.swift
//  NFTY
//
//  Created by Varun Kohli on 1/9/22.
//

import SwiftUI
import PromiseKit

struct WalletTokensCollectionHeaderImpl: View {
  let collection : Collection
  var body: some View {
    
    HStack(spacing:0) {
      Text(collection.info.name)
        .frame(alignment:.leading)
      Spacer()
      
      ObservedPromiseView(
        data:ObservablePromise(
          promise: after(seconds: 0.2).then { _ in collection.contract.indicativeFloor() } ),
        progress: {
          Spacer()
        },
        view: { floor in
          floor.map { floor in
            Text("Floor \(ethFormatter.string(for:floor)!)")
              .font(.footnote)
              .foregroundColor(.secondaryLabel)
              .frame(alignment:.trailing)
          }
        })
    }
    .padding([.leading,.trailing],10)
    .padding(5)
    .foregroundColor(.accentColor)
    .background(Color.systemBackground.opacity(0.9))
    .clipShape(RoundedRectangle(cornerRadius:10, style: .continuous))
    .shadow(color:.accentColor,radius:3)
    .padding(.top,1)
    .padding([.leading,.trailing],20)
  }
}

struct WalletTokensCollectionHeader: View {
  let collection : Collection
  var body: some View {
    
    switch(collection.contract.floorFetcher(collection)) {
    case .some:
      NavigationLink(
        destination:
          CollectionView(
            collection:collection,
            info:collection.info,
            loader: CompositeCollection.getLoader(collection: collection),
            page:.floor)
      ) {
        WalletTokensCollectionHeaderImpl(collection: collection)
      }
      
    case .none:
      WalletTokensCollectionHeaderImpl(collection: collection)
    }
  }
}
