//
//  ObservablePromise.swift
//  NFTY
//
//  Created by Varun Kohli on 5/11/21.
//

import Foundation
import PromiseKit

class ObservablePromise<T> : ObservableObject {
  
  enum State {
    case loading
    case loaded(T)
  }
  
  @Published var state : State = .loading
  private let promise : Promise<T>
  init(_ promise:Promise<T>) { self.promise = promise }
  
  func load() {
    switch(state) {
    case .loading:
      self.promise.done { val in
        self.state = .loaded(val)
      }.catch { print($0) }
    case .loaded:
      break
    }
  }
}
