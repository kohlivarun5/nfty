//
//  VaultTokensList.swift
//  NFTY
//
//  Created by Varun Kohli on 1/3/22.
//

import Foundation
import BigInt
import PromiseKit

class VaultTokensList : ObservableObject {
  @Published var tokens: [NFTWithLazyPrice] = []
  var eventsPublished: Published<[NFTWithLazyPrice]> { _tokens }
  var eventsPublisher: Published<[NFTWithLazyPrice]>.Publisher { $tokens }
  
  private let loadingChunk = 20
  private var isLoading = false
  private var lastIndex = -1
  
  let contract : ContractInterface
  let allHoldings : [BigUInt]
  
  init(contract : ContractInterface,
       allHoldings : [BigUInt])
  {
    self.contract = contract
    self.allHoldings = allHoldings
  }
  
  func loadMore(_ callback : @escaping () -> Void) {
    guard !isLoading else { return }
    
    self.isLoading = true
    
    self.lastIndex = self.lastIndex + 1
    if (self.lastIndex >= allHoldings.count) { self.isLoading = false }
    
    var filtered : [NFTWithLazyPrice] = []
    while(self.lastIndex < allHoldings.count && filtered.count < self.loadingChunk) {
      
      let tokenId = allHoldings[self.lastIndex]
      filtered.append(self.contract.getToken(UInt(tokenId)))
      self.lastIndex+=1
    }
    
    DispatchQueue.main.async {
      self.tokens.append(contentsOf: filtered)
      self.isLoading = false
    }
    
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
