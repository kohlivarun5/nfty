//
//  TokenPropertyFilters.swift
//  NFTY
//
//  Created by Varun Kohli on 8/29/21.
//

import SwiftUI

struct TokenPropertyFilters: View {
  
  @ObservedObject var nfts : TokensByPropertiesObject
  
  private func selectedValue(name:String) -> (value:String,percentile:Double)? {
    return nfts.selectedProperties
      .first { $0.name == name }
      .flatMap { (name:String,value:String) in
        nfts.availableProperties[name]?[value].map { (value:value,percentile:$0) }
      }
  }
  
  @State private var selectedValue : String = ""
  
  struct ListItem {
    let name:String
    let values:[String:Double]
    let selectedValue:(value:String,percentile:Double)?
  }
  
  private func propsToList(_ nfts:TokensByPropertiesObject) -> [ListItem] {
    nfts.availableProperties
      .map {
        return ListItem(name:$0.key,values:$0.value,selectedValue:selectedValue(name: $0.key))
      }
      .sorted {
        switch($0.selectedValue,$1.selectedValue) {
        case (.some,.none):
          return true
        case (.none,.some):
          return false
        case (.none,.none):
          return $0.values.count < $1.values.count
        case (.some(let first),.some(let second)):
          return first.percentile < second.percentile
        }
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
        
        let sorted = propsToList(nfts)
        ForEach(sorted.indices, id: \.self) { index in
          let item = sorted[index];
          
          switch(item.selectedValue) {
          case .none:
            Picker(
              selection:$selectedValue,
              label:
                VStack {
                  Text("\(item.name.capitalized)")
                    .padding()
                    .background(
                      RoundedCorners(
                        color: .secondarySystemBackground,
                        tl: 10, tr: 10, bl: 10, br: 10)
                    )
                    .colorMultiply(.flatOrange)
                }
              ,
              content: {
                ForEach(item.values.sorted(by:<),id:\.self.key, content: {
                  Text("\($0.key.capitalized) : \(String(format: $0.value > 0.019 ? "%.f%%" : "%.1f%%", $0.value * 100))")
                })
              }
            )
            .pickerStyle(MenuPickerStyle())
            .onChange(of: selectedValue) {
              self.nfts.onSelection(name: item.name, value: $0, isSelected:false)
            }
          case .some(let val):
            VStack(spacing:5) {
              Text("\(item.name.capitalized): \(val.value.capitalized)")
              Text(
                String(format: val.percentile > 0.019 ? "%.f%%" : "%.1f%%", val.percentile * 100)
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
            .colorMultiply(.flatGreen)
            .onTapGesture {
              self.selectedValue = ""
              self.nfts.onSelection(name: item.name, value: val.value, isSelected:true)
            }
          }
        }
      }
    }
  }
}


struct TokenPropertyFilters_Previews: PreviewProvider {
  static var previews: some View {
    TokenPropertyFilters(
      nfts: TokensByPropertiesObject(
        contract: SampleCollection.data.contract,
        properties: (SampleCollection.info.similarTokens?.properties)!,
        availableProperties: (SampleCollection.info.similarTokens?.availableProperties)!,
        selectedProperties: []
      )
    )
  }
}
