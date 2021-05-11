//
//  ObservedPromiseView.swift
//  NFTY
//
//  Created by Varun Kohli on 5/11/21.
//

import SwiftUI
import PromiseKit

struct ObservedPromiseView<T,ProgressView,ResolvedView> : View where ProgressView:View, ResolvedView : View {
  
  @ObservedObject var data : ObservablePromise<T>
  private let view : (T) -> ResolvedView
  private let progress : ProgressView
  
  init(data:ObservablePromise<T>,progress:ProgressView,@ViewBuilder view: @escaping (T) -> ResolvedView) {
    self.data = data
    self.progress = progress
    self.view = view
  }
  
  var body: some View {
    switch (data.state) {
    case .loading:
      self.progress
        .onAppear {
          self.data.load()
        }
    case .resolved(let t):
      self.view(t)
    }
  }
}

struct ObservedPromiseView_Previews: PreviewProvider {
  static var previews: some View {
    ObservedPromiseView(data:ObservablePromise(resolved:"Done"),progress:ProgressView()) { data in
      Text(data)
    }
  }
}
