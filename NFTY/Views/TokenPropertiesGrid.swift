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
        rows: [
          GridItem(.flexible()),
          GridItem(.flexible()),
          GridItem(.flexible())
        ],
        spacing: 5) {
        ForEach(properties.indices, id: \.self) { index in
          let item = properties[index];
          VStack {
            Text(item.name)
            Text(item.value)
            Text("\(item.percentile)")
          }
        }
      }
      //.padding(5)
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
