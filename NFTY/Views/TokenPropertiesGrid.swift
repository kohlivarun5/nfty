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
  
  struct Item {
    let name:String
    let value:String
    let percentile:Double
    let isSelected : Bool
  }
  
  @State private var action : Int? = nil
  @State private var selectedItem : Item?
  
  private func isSelected(item:SimilarTokensGetter.TokenAttributePercentile) -> Bool {
    return selectedProperties.contains { $0.name == item.name && $0.value == item.value }
  }
  
  private func selectedProperties(_ item:Item) -> [SimilarTokensGetter.TokenAttributePercentile] {
    return self.properties.filter { $0.name != item.name} + [SimilarTokensGetter.TokenAttributePercentile(name: item.name, value: item.value, percentile: item.percentile)]
  }
  
  private func selectedItems(_ item:Item) -> [(name:String,value:String)] {
    if (item.isSelected) {
      return selectedProperties.filter { $0.name != item.name }
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
                .contextMenu {
                  
                  ForEach(collection.info.similarTokens!.availableProperties![item.name]!.sorted(by:<),id:\.key) { val in
                    Button("\(val.key.capitalized) - \(String(format:  val.value > 0.019 ? "%.f%%" : "%.1f%%", val.value * 100))",
                           action: {
                            self.selectedItem = Item(name:item.name,value:val.key,percentile:val.value,isSelected: isSelected && item.value == val.key);
                            self.action = index;
                           })
                  }
                }
              NavigationLink(
                destination:TokensByPropertiesList(
                  properties:selectedProperties(selectedItem ?? Item(name:item.name,value:item.value,percentile:item.percentile,isSelected:isSelected)),
                  collection: collection,
                  nfts: TokensByPropertiesObject(
                    contract: collection.data.contract,
                    properties: properties,
                    selectedProperties: selectedItems( selectedItem ?? Item(name:item.name,value:item.value,percentile:item.percentile,isSelected:isSelected))
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
