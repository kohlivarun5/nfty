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
  
  @Published var error: String? = nil
  
  private var isLoading = false
  private var lastIndex = -1
  
  let fetcher : PagedTokensFetcher
  
  init(fetcher : PagedTokensFetcher)
  {
    self.fetcher = fetcher
  }
  
  func loadMore(_ callback : @escaping () -> Void) {
    guard !isLoading else { return }
    
    self.isLoading = true
    
    fetcher
      .fetchNext()
      .done(on:.main) {
        print("Adding \($0.count) tokens")
        self.tokens.append(contentsOf: $0)
      }
      .catch(on:.main) {
        print($0)
        self.error = "Failed to load items"
      }
      .finally(on:.main) {
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
