//
//  ObservedPromiseView.swift
//  NFTY
//
//  Created by Varun Kohli on 5/11/21.
//

import SwiftUI
import PromiseKit

struct ObservedPromiseView<T,ResolvedView>: View where ResolvedView : View {
  
  @ObservedObject var data : ObservablePromise<T>
  private let view : (T) -> ResolvedView
  
  init(data:ObservablePromise<T>,@ViewBuilder view: @escaping (T) -> ResolvedView) {
    self.data = data
    self.view = view
  }
  
  var body: some View {
    switch (data.state) {
    case .loading:
      ProgressView()
        .onAppear {
          self.data.load()
        }
    case .loaded(let t):
      self.view(t)
    }
  }
}

struct ObservedPromiseView_Previews: PreviewProvider {
  static var previews: some View {
    ObservedPromiseView(data:ObservablePromise(Promise.value("Done"))) { data in
      Text(data)
    }
  }
}
