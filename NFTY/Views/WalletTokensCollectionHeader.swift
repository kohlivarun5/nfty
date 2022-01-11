//
//  WalletTokensCollectionHeader.swift
//  NFTY
//
//  Created by Varun Kohli on 1/9/22.
//

import SwiftUI

struct WalletTokensCollectionHeader: View {
  let collection : Collection
  var body: some View {
    HStack {
      Spacer()
      ObservedPromiseView(
        data:ObservablePromise(promise: collection.data.contract.indicativeFloor()),
        progress: {
          Text(collection.info.name)
        },
        view: { floor in
          switch(floor) {
          case .none:
            Text(collection.info.name)
          case .some(let floor):
            VStack(spacing:0) {
              Text(collection.info.name)
              Text("Floor \(ethFormatter.string(for:floor)!)")
                .font(.footnote)
                .foregroundColor(.secondaryLabel)
            }
          }
        })
        .padding(5)
      Spacer()
    }
    .foregroundColor(.accentColor)
    .background(Color.systemBackground.opacity(0.9))
    .clipShape(RoundedRectangle(cornerRadius:10, style: .continuous))
    .shadow(color:.accentColor,radius:3)
    .padding(.top,2)
    .padding([.leading,.trailing],20)
  }
}
