//
//  TokensListPaged.swift
//  NFTY
//
//  Created by Varun Kohli on 2/6/22.
//

import Foundation

import BigInt
import PromiseKit

class TokensListPaged : ObservableObject {
  @Published var tokens: [NFTWithLazyPrice] = []
  var eventsPublished: Published<[NFTWithLazyPrice]> { _tokens }
  var eventsPublisher: Published<[NFTWithLazyPrice]>.Publisher { $tokens }
  
  let loadingChunk = 20
  private var isLoading = false
  private var lastIndex = -1
  
  let contract : ContractInterface
  var allHoldings : [BigUInt]
  
  init(contract : ContractInterface,
       allHoldings : [BigUInt],
       rankings:RarityRanking?)
  {
    self.contract = contract
    
    self.allHoldings = allHoldings
    
    rankings.map { rankings in
      self.allHoldings.sort { left,right in
        switch(rankings.getRank(UInt(left)),rankings.getRank(UInt(right))) {
        case (.some(let leftRank),.some(let rightRank)):
          return leftRank < rightRank
        default:
          return left < right
        }
        
      }
    }
    
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
