//
//  TokenPropertiesGrid.swift
//  NFTY
//
//  Created by Varun Kohli on 8/14/21.
//

import SwiftUI

struct TokenPropertiesGrid: View {
  let properties : [SimilarTokensGetter.TokenAttributePercentile]
  
  var body: some View {
    ScrollView(.horizontal) {
      LazyHGrid(
        rows:[
          GridItem(.fixed(70)),
          GridItem(.fixed(70)),
        ]
      ) {
        ForEach(properties.indices, id: \.self) { index in
          let item = properties[index];
          VStack(spacing:5) {
            Text("\(item.name.capitalized): \(item.value.capitalized)")
            Text(
              String(format: "%.1f%%", item.percentile * 100)
            )
            .bold()
          }
          .padding(10)
          .background(
            RoundedCorners(
              color: .secondarySystemBackground,
              tl: 10, tr: 10, bl: 10, br: 10)
          )
          .colorMultiply(.flatOrange)
          .padding(5)
        }
      }
      .padding([.leading,.trailing])
      .padding(.top,15)
      .padding(.bottom,150)
    }
  }
}

struct TokenPropertiesGrid_Previews: PreviewProvider {
  static var previews: some View {
    TokenPropertiesGrid(
      properties:[
        SimilarTokensGetter.TokenAttributePercentile(name: "sdas", value: "Ssadsa", percentile: 0.2),
        SimilarTokensGetter.TokenAttributePercentile(name: "sdas", value: "Ssadsa", percentile: 0.2),
        SimilarTokensGetter.TokenAttributePercentile(name: "sdas", value: "Ssadsa", percentile: 0.2),
        SimilarTokensGetter.TokenAttributePercentile(name: "sdas", value: "Ssadsa", percentile: 0.2),
      ]
    )
  }
}