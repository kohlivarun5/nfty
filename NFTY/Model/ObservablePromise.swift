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
    case resolved(T)
  }
  
  @Published var state : State = .loading
  private let promise : Promise<T>
  init(promise:Promise<T>) { self.promise = promise }
  init(resolved:T) {
    self.promise = Promise.value(resolved)
    self.state = .resolved(resolved)
  }
  
  func load() {
    switch(state) {
    case .loading:
      self.promise.done { val in
        self.state = .resolved(val)
      }.catch { print($0) }
    case .resolved:
      break
    }
  }
}
