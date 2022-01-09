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
        VStack(spacing:0) {
          Text(collection.info.name)
            .font(.subheadline)
        }
        .padding(5)
        Spacer()
      }
      .foregroundColor(.accentColor)
      .background(Color.tertiarySystemBackground)
      /* .overlay(
        Capsule()
          .stroke(Color.accentColor, lineWidth: 4)
      ) */
      .clipShape(Capsule())
      .padding([.leading,.trailing],30)
    }
}
