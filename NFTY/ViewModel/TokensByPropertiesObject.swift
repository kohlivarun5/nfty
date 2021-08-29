//
//  TokensByPropertiesObject.swift
//  NFTY
//
//  Created by Varun Kohli on 8/29/21.
//

import Foundation


class TokensByPropertiesObject : ObservableObject {
  @Published var tokens: [NFTWithLazyPrice] = []
  var eventsPublished: Published<[NFTWithLazyPrice]> { _tokens }
  var eventsPublisher: Published<[NFTWithLazyPrice]>.Publisher { $tokens }
  
  private let loadingChunk = 50
  private var isLoading = false
  private var lastIndex = -1
  let contract : ContractInterface
  let properties : [[SimilarTokensGetter.TokenAttributePercentile]]
  let selectedProperties : [(name:String,value:String)]
  
  init(contract : ContractInterface,
       properties : [[SimilarTokensGetter.TokenAttributePercentile]],
       selectedProperties : [(name:String,value:String)])
  {
    self.contract = contract
    self.properties = properties
    self.selectedProperties = selectedProperties
  }
  
  func loadMore(_ callback : @escaping () -> Void) {
    guard !isLoading else { return }
    
    lastIndex = lastIndex + 1
    if (lastIndex >= properties.count) { return }
    
    self.isLoading = true
    var filtered : [NFTWithLazyPrice] = []
    while(lastIndex < properties.count && filtered.count < loadingChunk) {
      
      let matched = properties[safe:lastIndex]?.filter { property in
        selectedProperties.contains { selection in
          selection.name == property.name && selection.value == property.value
        }
      }
      
      
      if (selectedProperties.count == matched?.count) {
        // found, push into filtered
        filtered.append(contract.getToken(UInt(lastIndex)))
      }
      lastIndex+=1
    }
    
    DispatchQueue.main.async {
      self.tokens.append(contentsOf: filtered)
    }
    
    self.isLoading = false
  }
  
  func next(currentIndex:Int?) {
    guard let index = currentIndex else {
      loadMore() {}
      return
    }
    let thresholdIndex = self.tokens.index(self.tokens.endIndex, offsetBy: -5)
    if index >= thresholdIndex {
      loadMore() {}
    }
  }
}
