//
//  TokensByPropertiesObject.swift
//  NFTY
//
//  Created by Varun Kohli on 8/29/21.
//

import Foundation


class TokensByPropertiesObject : ObservableObject {
  
  let tokenProperties : [[SimilarTokensGetter.TokenAttributePercentile]]
  
  let availableProperties : [String:[String:Double]]
  @Published var selectedProperties : [(name:String,value:String)]
  
  @Published var tokens: [NFTWithLazyPrice] = []
  var eventsPublished: Published<[NFTWithLazyPrice]> { _tokens }
  var eventsPublisher: Published<[NFTWithLazyPrice]>.Publisher { $tokens }
  
  private let loadingChunk = 50
  private var isLoading = false
  private var lastIndex = -1
  let contract : ContractInterface
  
  init(contract : ContractInterface,
       properties : [[SimilarTokensGetter.TokenAttributePercentile]],
       availableProperties : [String:[String:Double]],
       selectedProperties : [(name:String,value:String)])
  {
    self.contract = contract
    self.tokenProperties = properties
    self.availableProperties = availableProperties
    self.selectedProperties = selectedProperties
  }
  
  func loadMore(_ callback : @escaping () -> Void) {
    guard !isLoading else { return }
    
    lastIndex = lastIndex + 1
    if (lastIndex >= tokenProperties.count) { return }
    
    self.isLoading = true
    var filtered : [NFTWithLazyPrice] = []
    while(lastIndex < tokenProperties.count && filtered.count < loadingChunk) {
      
      let matched = tokenProperties[safe:lastIndex]?.filter { property in
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
  
  func onSelection(name:String,value:String,isSelected:Bool) {
    print(self.selectedProperties)
    // first remove if already, then add if needed
    self.selectedProperties = selectedProperties.filter { $0.name != name || $0.value != value }
    if (!isSelected) {
      self.selectedProperties = selectedProperties + [(name:name,value:value)]
    }
    
    print(self.selectedProperties)
    
    self.tokens = []
    self.lastIndex = -1
    self.isLoading = false
    loadMore() {}
    
  }
  
}
