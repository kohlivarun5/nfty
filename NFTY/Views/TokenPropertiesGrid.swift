//
//  TokenPropertiesGrid.swift
//  NFTY
//
//  Created by Varun Kohli on 8/14/21.
//

import SwiftUI

struct TokenPropertiesGrid: View {
  let properties : [SimilarTokensGetter.TokenAttributePercentile]
  let collection : Collection
  let selectedProperties : [(name:String,value:String)]
  
  @State private var action : Int? = nil
  
  private func isSelected(item:SimilarTokensGetter.TokenAttributePercentile) -> Bool {
    return selectedProperties.contains { $0.name == item.name && $0.value == item.value }
  }
  
  private func itemTapped(item:SimilarTokensGetter.TokenAttributePercentile,isSelected:Bool) -> [(name:String,value:String)] {
    if (isSelected) {
      return selectedProperties.filter { $0.name != item.name || $0.value != item.value }
    } else {
      return selectedProperties + [(name:item.name,value:item.value)]
    }
  }
  
  var body: some View {
    ScrollView(.horizontal) {
      LazyHGrid(
        rows:[
          GridItem(.fixed(60)),
          GridItem(.fixed(60)),
        ]
      ) {
        let sorted = properties
          .filter { $0.percentile < 1 }
          .sorted {
            switch(isSelected(item:$0),isSelected(item:$1)) {
            case (true,false):
              return true
            case (false,true):
              return false
            case (true,true),(false,false):
              return $0.percentile < $1.percentile
            }
          }
        ForEach(sorted.indices, id: \.self) { index in
          let item = sorted[index];
          let isSelected = isSelected(item:item);
          
          let view =
            VStack(spacing:5) {
              Text("\(item.name.capitalized): \(item.value.capitalized)")
              Text(
                String(format: item.percentile > 0.019 ? "%.f%%" : "%.1f%%", item.percentile * 100)
              )
              .bold()
            }
            .font(.system(size: 13))
            .padding(10)
            .background(
              RoundedCorners(
                color: .secondarySystemBackground,
                tl: 10, tr: 10, bl: 10, br: 10)
            )
            .colorMultiply(isSelected ? .flatGreen : .flatOrange);
          
          switch(collection.info.similarTokens?.properties) {
          case .none:
            view
          case .some(let properties):
            ZStack {
              view
                .onTapGesture { self.action = index }
              NavigationLink(
                destination:TokensByPropertiesList(
                  properties:self.properties,
                  collection: collection,
                  nfts: TokensByPropertiesObject(
                    contract: collection.data.contract,
                    properties: properties,
                    availableProperties: (collection.info.similarTokens?.availableProperties)!,
                    selectedProperties: itemTapped(item:item,isSelected:isSelected)
                  )
                ), tag:index,selection:$action
              ) {}
              .hidden()
            }
          }
        }
      }
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
      ],
      collection: SampleCollection,
      selectedProperties: []
    )
  }
}
